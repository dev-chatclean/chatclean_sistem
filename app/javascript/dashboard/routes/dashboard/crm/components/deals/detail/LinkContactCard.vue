<script setup>
import { computed, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { debounce } from '@chatwoot/utils';
import ContactAPI from 'dashboard/api/contacts';
import { useAlert } from 'dashboard/composables';
import { parseAPIErrorResponse } from 'dashboard/store/utils/api';
import { SEARCH_DEBOUNCE_MS } from '../../../constants';

const props = defineProps({
  contact: { type: Object, default: null },
});

const emit = defineEmits(['link', 'unlink']);

const { t } = useI18n();

const mode = ref('search');
const query = ref('');
const results = ref([]);
const selected = ref(null);
const newContact = ref({ name: '', phone: '' });
const isBusy = ref(false);

const search = debounce(async value => {
  if (!value.trim()) {
    results.value = [];
    return;
  }
  try {
    const { data } = await ContactAPI.search(value.trim());
    results.value = data.payload.slice(0, 5);
  } catch (error) {
    results.value = [];
  }
}, SEARCH_DEBOUNCE_MS);

watch(query, value => {
  selected.value = null;
  search(value);
});

const normalizedPhone = computed(() => {
  const digits = newContact.value.phone.replace(/\D/g, '');
  if (!digits) return '';
  return newContact.value.phone.trim().startsWith('+')
    ? `+${digits}`
    : `+55${digits}`;
});

const canLink = computed(() =>
  mode.value === 'search'
    ? Boolean(selected.value)
    : Boolean(newContact.value.name.trim() && normalizedPhone.value)
);

const link = async () => {
  if (!canLink.value || isBusy.value) return;
  if (mode.value === 'search') {
    emit('link', selected.value);
    return;
  }
  isBusy.value = true;
  try {
    const { data } = await ContactAPI.create({
      name: newContact.value.name.trim(),
      phone_number: normalizedPhone.value,
    });
    emit('link', data.payload.contact);
    newContact.value = { name: '', phone: '' };
  } catch (error) {
    const message = parseAPIErrorResponse(error);
    useAlert(
      typeof message === 'string'
        ? message
        : t('CRM_DEALS.CONTACT.CREATE_ERROR')
    );
  } finally {
    isBusy.value = false;
  }
};

const inputClass =
  'reset-base w-full h-11 px-3 text-sm rounded-xl border border-n-slate-6 bg-transparent text-n-slate-12 focus:outline-none focus:border-n-brand';
</script>

<template>
  <div
    v-if="props.contact"
    class="flex items-start gap-3 p-4 border rounded-2xl border-n-slate-6"
  >
    <span
      class="flex items-center justify-center rounded-full size-10 shrink-0 bg-n-alpha-2 text-n-slate-11"
    >
      <span class="i-lucide-user size-4" />
    </span>
    <div class="flex flex-col flex-1 min-w-0 gap-0.5">
      <span class="text-sm font-semibold text-n-slate-12 truncate">
        {{ props.contact.name }}
      </span>
      <span
        v-if="props.contact.phone_number"
        class="text-label-small text-n-slate-11 truncate"
      >
        {{ props.contact.phone_number }}
      </span>
      <span
        v-if="props.contact.email"
        class="text-label-small text-n-slate-11 truncate"
      >
        {{ props.contact.email }}
      </span>
    </div>
    <button
      type="button"
      class="text-label-small text-n-slate-11 hover:text-n-ruby-11"
      @click="emit('unlink')"
    >
      {{ t('CRM_DEALS.CONTACT.REMOVE') }}
    </button>
  </div>
  <div
    v-else
    class="flex flex-col gap-3 p-4 border border-dashed rounded-2xl border-n-slate-6"
  >
    <div class="flex items-center gap-3">
      <span
        class="flex items-center justify-center rounded-full size-10 shrink-0 bg-n-alpha-2 text-n-slate-11"
      >
        <span class="i-lucide-link size-4" />
      </span>
      <div class="flex flex-col gap-0.5">
        <span class="text-base font-semibold text-n-slate-12">
          {{ t('CRM_DEALS.LINK.TITLE') }}
        </span>
        <span class="text-sm text-n-slate-11">
          {{ t('CRM_DEALS.LINK.DESCRIPTION') }}
        </span>
      </div>
    </div>
    <div class="grid grid-cols-2 p-1 rounded-xl border border-n-slate-6">
      <button
        v-for="option in ['search', 'create']"
        :key="option"
        type="button"
        class="py-2 text-sm rounded-lg"
        :class="
          mode === option
            ? 'bg-n-brand/15 text-n-blue-11 font-medium'
            : 'text-n-slate-11 hover:text-n-slate-12'
        "
        @click="mode = option"
      >
        {{ t(`CRM_DEALS.LINK.${option.toUpperCase()}`) }}
      </button>
    </div>
    <template v-if="mode === 'search'">
      <div class="relative">
        <span
          class="absolute i-lucide-search size-4 top-3.5 start-3 text-n-slate-10"
        />
        <input
          v-model="query"
          type="search"
          :placeholder="t('CRM_DEALS.CONTACT.SEARCH_PLACEHOLDER')"
          :class="inputClass"
          class="ps-9"
        />
      </div>
      <div
        v-if="results.length"
        class="flex flex-col gap-1 p-1 rounded-xl border border-n-slate-6"
      >
        <button
          v-for="item in results"
          :key="item.id"
          type="button"
          class="flex flex-col px-3 py-2 text-start rounded-lg"
          :class="
            selected?.id === item.id ? 'bg-n-brand/15' : 'hover:bg-n-alpha-2'
          "
          @click="selected = item"
        >
          <span class="text-sm text-n-slate-12">{{ item.name }}</span>
          <span class="text-label-small text-n-slate-11">
            {{ item.phone_number || item.email }}
          </span>
        </button>
      </div>
      <span
        v-else
        class="flex items-center gap-2 px-3 py-2.5 text-sm border border-dashed rounded-xl border-n-slate-6 text-n-slate-11"
      >
        <span class="i-lucide-search size-4" />
        {{ t('CRM_DEALS.LINK.SEARCH_HINT') }}
      </span>
    </template>
    <template v-else>
      <input
        v-model="newContact.name"
        type="text"
        :placeholder="t('CRM_DEALS.LINK.NAME')"
        :class="inputClass"
      />
      <input
        v-model="newContact.phone"
        type="tel"
        :placeholder="t('CRM_DEALS.LINK.PHONE')"
        :class="inputClass"
      />
    </template>
    <button
      type="button"
      class="h-11 text-sm font-medium rounded-xl disabled:cursor-not-allowed"
      :class="
        canLink
          ? 'bg-n-brand text-white hover:bg-n-brand/90'
          : 'bg-n-alpha-2 text-n-slate-10'
      "
      :disabled="!canLink || isBusy"
      @click="link"
    >
      {{ t('CRM_DEALS.LINK.SUBMIT') }}
    </button>
  </div>
</template>
