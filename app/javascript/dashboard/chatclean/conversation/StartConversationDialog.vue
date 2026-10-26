<script setup>
import { computed, defineAsyncComponent, reactive, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRouter } from 'vue-router';
import { debounce } from '@chatwoot/utils';
import { useAlert } from 'dashboard/composables';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import Select from 'dashboard/components-next/select/Select.vue';
import TextArea from 'dashboard/components-next/textarea/TextArea.vue';
import PhoneNumberInput from 'dashboard/components-next/phonenumberinput/PhoneNumberInput.vue';
import WhatsAppOptions from 'dashboard/components-next/NewConversation/components/WhatsAppOptions.vue';
import {
  createContactSearcher,
  createNewContact,
  fetchContactableInboxes,
} from 'dashboard/components-next/NewConversation/helpers/composeConversationHelper';
import { INBOX_TYPES } from 'dashboard/helper/inbox';
import ConversationApi from 'dashboard/api/conversations';
import { frontendURL, conversationUrl } from 'dashboard/helper/URLHelper';

const EmojiIconPicker = defineAsyncComponent(
  () =>
    import('dashboard/components-next/emoji-icon-picker/EmojiIconPicker.vue')
);

// Criar atendimento (US 15, CA 15.6): contato pelo número com DDI ou pela busca, canal, departamento
// e a mensagem inicial. O atendimento nasce atribuído a quem iniciou. No WhatsApp oficial, a Meta só
// aceita um modelo aprovado no primeiro contato, então a mensagem vira a escolha do modelo.

// Canais que falam com o cliente pelo telefone. O de API inclui o WhatsApp por QR Code (E4).
const PHONE_CHANNELS = [
  INBOX_TYPES.WHATSAPP,
  INBOX_TYPES.SMS,
  INBOX_TYPES.TWILIO,
  INBOX_TYPES.API,
];
const MIN_PHONE_DIGITS = 10;

const { t } = useI18n();
const store = useStore();
const router = useRouter();
const currentUser = useMapGetter('getCurrentUser');
const currentAccountId = useMapGetter('getCurrentAccountId');
const allInboxes = useMapGetter('inboxes/getInboxes');
const teams = useMapGetter('teams/getTeams');

const dialogRef = ref(null);
const searchContacts = createContactSearcher();
const form = reactive({
  phone: '',
  query: '',
  inboxId: '',
  teamId: '',
  message: '',
});
const selectedContact = ref(null);
const searchResults = ref([]);
const contactInboxes = ref([]);
const showEmojiPicker = ref(false);
const isSubmitting = ref(false);

const phoneDigits = computed(() => form.phone.replace(/\D/g, ''));
const hasNewPhone = computed(
  () => !selectedContact.value && phoneDigits.value.length >= MIN_PHONE_DIGITS
);

// Contato existente: os canais pelos quais ele pode ser contatado. Número novo: os canais por telefone.
const inboxes = computed(() => {
  if (selectedContact.value) return contactInboxes.value;
  if (!hasNewPhone.value) return [];
  return allInboxes.value.filter(inbox =>
    PHONE_CHANNELS.includes(inbox.channel_type)
  );
});
const inboxOptions = computed(() =>
  inboxes.value.map(inbox => ({ value: inbox.id, label: inbox.name }))
);
const teamOptions = computed(() => [
  { value: '', label: t('CHATCLEAN.START_CONVERSATION.NO_TEAM') },
  ...teams.value.map(team => ({ value: team.id, label: team.name })),
]);
const selectedInbox = computed(() =>
  inboxes.value.find(inbox => inbox.id === form.inboxId)
);
const isWhatsAppTemplateInbox = computed(() => {
  const inbox = selectedInbox.value;
  if (!inbox) return false;
  const channelType = inbox.channel_type || inbox.channelType;
  return (
    channelType === INBOX_TYPES.WHATSAPP ||
    (channelType === INBOX_TYPES.TWILIO && inbox.medium === 'whatsapp')
  );
});
const canSubmit = computed(
  () =>
    Boolean(selectedInbox.value) &&
    !isWhatsAppTemplateInbox.value &&
    Boolean(form.message.trim())
);

const selectContact = async contact => {
  selectedContact.value = contact;
  searchResults.value = [];
  form.query = '';
  form.inboxId = '';
  contactInboxes.value = await fetchContactableInboxes(contact.id);
};

const clearContact = () => {
  selectedContact.value = null;
  contactInboxes.value = [];
  form.inboxId = '';
};

const runSearch = debounce(async query => {
  const results = await searchContacts(query);
  if (results) searchResults.value = results.slice(0, 5);
}, 300);

watch(
  () => form.query,
  query => {
    if (query.trim().length < 2) {
      searchResults.value = [];
      return;
    }
    runSearch(query);
  }
);

// Um número já cadastrado usa o contato existente.
const findContactByPhone = debounce(async phone => {
  const results = await searchContacts(phone, { reachableOnly: false });
  const match = results?.find(contact => contact.phoneNumber === phone);
  if (match && form.phone === phone) selectContact(match);
}, 400);

watch(
  () => form.phone,
  phone => {
    if (selectedContact.value?.phoneNumber !== phone) clearContact();
    if (phoneDigits.value.length >= MIN_PHONE_DIGITS) findContactByPhone(phone);
  }
);

const open = () => {
  Object.assign(form, {
    phone: '',
    query: '',
    inboxId: '',
    teamId: '',
    message: '',
  });
  clearContact();
  searchResults.value = [];
  store.dispatch('teams/get');
  store.dispatch('inboxes/get');
  dialogRef.value?.open();
};

const addEmoji = emoji => {
  form.message += emoji;
  showEmojiPicker.value = false;
};

const start = async message => {
  isSubmitting.value = true;
  try {
    const contact =
      selectedContact.value || (await createNewContact(form.phone));
    const { data } = await ConversationApi.create({
      inbox_id: form.inboxId,
      contact_id: contact.id,
      source_id: selectedInbox.value.sourceId,
      assignee_id: currentUser.value.id,
      team_id: form.teamId || undefined,
      message,
    });
    dialogRef.value?.close();
    useAlert(t('CHATCLEAN.START_CONVERSATION.SUCCESS'));
    router.push(
      frontendURL(
        conversationUrl({ accountId: currentAccountId.value, id: data.id })
      )
    );
  } catch (error) {
    useAlert(
      error?.response?.data?.message ||
        error?.response?.data?.error ||
        t('CHATCLEAN.START_CONVERSATION.ERROR')
    );
  } finally {
    isSubmitting.value = false;
  }
};

const handleConfirm = () => {
  if (canSubmit.value) start({ content: form.message.trim() });
};

const handleTemplate = ({ message, templateParams }) =>
  start({ content: message, template_params: templateParams });

defineExpose({ open });
</script>

<template>
  <Dialog
    ref="dialogRef"
    :title="t('CHATCLEAN.START_CONVERSATION.TITLE')"
    :description="t('CHATCLEAN.START_CONVERSATION.DESCRIPTION')"
    :confirm-button-label="t('CHATCLEAN.START_CONVERSATION.CONFIRM')"
    :show-confirm-button="!isWhatsAppTemplateInbox"
    :disable-confirm-button="!canSubmit"
    :is-loading="isSubmitting"
    width="xl"
    @confirm="handleConfirm"
  >
    <div class="flex flex-col gap-5">
      <section class="flex flex-col gap-3">
        <h4
          class="flex items-center gap-2 text-xs font-medium uppercase text-n-slate-11"
        >
          <Icon icon="i-lucide-user" class="size-4" />
          {{ t('CHATCLEAN.START_CONVERSATION.CONTACT') }}
        </h4>
        <PhoneNumberInput
          v-model="form.phone"
          :placeholder="t('CHATCLEAN.START_CONVERSATION.PHONE_PLACEHOLDER')"
          data-test="start-phone"
        />
        <div
          v-if="selectedContact"
          class="flex items-center justify-between gap-2 px-3 py-2 rounded-lg bg-n-alpha-2 text-sm text-n-slate-12"
          data-test="start-selected-contact"
        >
          <span class="truncate">
            {{ selectedContact.name }}
            <span class="text-n-slate-11">
              {{ selectedContact.phoneNumber || selectedContact.email }}
            </span>
          </span>
          <Button
            icon="i-lucide-x"
            size="xs"
            variant="ghost"
            color="slate"
            :title="t('CHATCLEAN.START_CONVERSATION.CLEAR_CONTACT')"
            @click="clearContact"
          />
        </div>
        <div v-else class="relative flex flex-col gap-1">
          <Input
            v-model="form.query"
            :placeholder="t('CHATCLEAN.START_CONVERSATION.SEARCH_PLACEHOLDER')"
            :message="t('CHATCLEAN.START_CONVERSATION.SEARCH_HINT')"
            data-test="start-search"
          />
          <ul
            v-if="searchResults.length"
            class="absolute z-10 w-full mt-11 overflow-hidden border rounded-lg shadow-lg border-n-weak bg-n-alpha-3 backdrop-blur-[100px]"
          >
            <li v-for="contact in searchResults" :key="contact.id">
              <button
                type="button"
                class="flex w-full gap-2 px-3 py-2 text-sm text-start text-n-slate-12 hover:bg-n-alpha-2"
                data-test="start-search-result"
                @click="selectContact(contact)"
              >
                <span class="truncate">{{ contact.name }}</span>
                <span class="truncate text-n-slate-11">
                  {{ contact.phoneNumber || contact.email }}
                </span>
              </button>
            </li>
          </ul>
        </div>
      </section>

      <section class="flex flex-col gap-3">
        <h4
          class="flex items-center gap-2 text-xs font-medium uppercase text-n-slate-11"
        >
          <Icon icon="i-lucide-messages-square" class="size-4" />
          {{ t('CHATCLEAN.START_CONVERSATION.CHANNEL_AND_TEAM') }}
        </h4>
        <p
          v-if="(selectedContact || hasNewPhone) && !inboxOptions.length"
          class="text-sm text-n-amber-11"
          data-test="start-no-inbox"
        >
          {{ t('CHATCLEAN.START_CONVERSATION.NO_INBOX') }}
        </p>
        <Select
          v-model="form.inboxId"
          :options="inboxOptions"
          :placeholder="t('CHATCLEAN.START_CONVERSATION.CHANNEL_PLACEHOLDER')"
          :disabled="!inboxOptions.length"
          class="!w-full [&_select]:w-full"
          data-test="start-inbox"
        />
        <Select
          v-model="form.teamId"
          :options="teamOptions"
          class="!w-full [&_select]:w-full"
          data-test="start-team"
        />
      </section>

      <section class="flex flex-col gap-3">
        <h4
          class="flex items-center gap-2 text-xs font-medium uppercase text-n-slate-11"
        >
          <Icon icon="i-lucide-message-square-text" class="size-4" />
          {{ t('CHATCLEAN.START_CONVERSATION.MESSAGE') }}
        </h4>
        <div
          v-if="isWhatsAppTemplateInbox"
          class="flex items-center justify-between gap-3 text-sm text-n-slate-11"
        >
          {{ t('CHATCLEAN.START_CONVERSATION.WHATSAPP_TEMPLATE_HINT') }}
          <WhatsAppOptions
            :inbox-id="form.inboxId"
            @send-message="handleTemplate"
          />
        </div>
        <div v-else class="relative">
          <TextArea
            v-model="form.message"
            :placeholder="t('CHATCLEAN.START_CONVERSATION.MESSAGE_PLACEHOLDER')"
            data-test="start-message"
          />
          <Button
            icon="i-lucide-smile"
            size="xs"
            variant="ghost"
            color="slate"
            class="absolute top-2 end-2"
            :title="t('CHATCLEAN.START_CONVERSATION.EMOJI')"
            @click="showEmojiPicker = !showEmojiPicker"
          />
          <EmojiIconPicker
            v-if="showEmojiPicker"
            v-on-clickaway="() => (showEmojiPicker = false)"
            mode="emoji"
            class="absolute z-20 end-0 bottom-full mb-2"
            @select="addEmoji($event.value)"
          />
        </div>
      </section>
    </div>
  </Dialog>
</template>
