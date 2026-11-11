<script setup>
import { ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRoute } from 'vue-router';
import ContactAPI from 'dashboard/api/contacts';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import { conversationUrl, frontendURL } from 'dashboard/helper/URLHelper';
import { formatDateTime } from './dealTime';

const props = defineProps({
  contact: { type: Object, default: null },
});

const { t, locale } = useI18n();
const route = useRoute();

const conversations = ref([]);
const isLoading = ref(false);

const load = async () => {
  conversations.value = [];
  if (!props.contact) return;
  isLoading.value = true;
  try {
    const { data } = await ContactAPI.getConversations(props.contact.id);
    conversations.value = data.payload;
  } finally {
    isLoading.value = false;
  }
};

watch(() => props.contact?.id, load, { immediate: true });

const linkTo = conversation =>
  frontendURL(
    conversationUrl({ accountId: route.params.accountId, id: conversation.id })
  );

const lastMessage = conversation =>
  conversation.messages?.[conversation.messages.length - 1]?.content || '';
</script>

<template>
  <div
    v-if="!contact"
    class="flex flex-col items-center gap-2 py-10 text-center"
  >
    <span
      class="flex items-center justify-center rounded-xl size-12 border border-n-slate-6 text-n-slate-11"
    >
      <span class="i-lucide-link size-5" />
    </span>
    <span class="text-base font-semibold text-n-slate-12">
      {{ t('CRM_DEALS.DETAIL.NO_CONTACT_TITLE') }}
    </span>
    <span class="text-sm text-n-slate-11">
      {{ t('CRM_DEALS.DETAIL.NO_CONTACT_CONVERSATIONS') }}
    </span>
  </div>
  <div v-else-if="isLoading" class="flex justify-center py-6"><Spinner /></div>
  <p
    v-else-if="!conversations.length"
    class="py-6 text-base text-center text-n-slate-11"
  >
    {{ t('CRM_DEALS.DETAIL.NO_CONVERSATIONS') }}
  </p>
  <ul v-else class="flex flex-col gap-2 p-0 m-0 list-none">
    <li v-for="conversation in conversations" :key="conversation.id">
      <a
        :href="linkTo(conversation)"
        class="flex items-center justify-between gap-3 px-4 py-3 border rounded-xl border-n-weak hover:bg-n-alpha-1"
      >
        <span class="flex flex-col min-w-0">
          <span class="text-sm font-medium text-n-slate-12">
            {{ t('CRM_DEALS.NUMBER', { number: conversation.id }) }} ·
            {{
              t(
                `CRM_DEALS.DETAIL.CONVERSATION_STATUS.${conversation.status.toUpperCase()}`
              )
            }}
          </span>
          <span class="text-label-small text-n-slate-11 truncate">
            {{ lastMessage(conversation) }}
          </span>
        </span>
        <span class="text-label-small text-n-slate-11 shrink-0">
          {{
            formatDateTime(
              conversation.last_activity_at || conversation.timestamp,
              locale
            )
          }}
        </span>
      </a>
    </li>
  </ul>
</template>
