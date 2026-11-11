<script setup>
import { computed, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { debounce } from '@chatwoot/utils';
import ContactAPI from 'dashboard/api/contacts';
import { parseAPIErrorResponse } from 'dashboard/store/utils/api';
import { useAlert } from 'dashboard/composables';
import Button from 'dashboard/components-next/button/Button.vue';
import { SEARCH_DEBOUNCE_MS } from '../../constants';

const contact = defineModel({ type: Object, default: null });

const { t } = useI18n();

const query = ref('');
const results = ref([]);
const isSearching = ref(false);
const isCreating = ref(false);

const PHONE_PATTERN = /^\+?[\d\s()-]{8,}$/;

const phoneCandidate = computed(() => {
  const value = query.value.trim();
  if (!PHONE_PATTERN.test(value)) return '';
  const digits = value.replace(/\D/g, '');
  return value.startsWith('+') ? `+${digits}` : `+55${digits}`;
});

const search = debounce(async value => {
  if (!value.trim()) {
    results.value = [];
    isSearching.value = false;
    return;
  }
  try {
    const { data } = await ContactAPI.search(value.trim());
    results.value = data.payload.slice(0, 6);
  } catch (error) {
    results.value = [];
  } finally {
    isSearching.value = false;
  }
}, SEARCH_DEBOUNCE_MS);

watch(query, value => {
  isSearching.value = Boolean(value.trim());
  search(value);
});

const select = item => {
  contact.value = {
    id: item.id,
    name: item.name,
    phone_number: item.phone_number,
    email: item.email,
  };
  query.value = '';
  results.value = [];
};

const createByPhone = async () => {
  isCreating.value = true;
  try {
    const { data } = await ContactAPI.create({
      name: phoneCandidate.value,
      phone_number: phoneCandidate.value,
    });
    select(data.payload.contact);
  } catch (error) {
    const message = parseAPIErrorResponse(error);
    useAlert(
      typeof message === 'string'
        ? message
        : t('CRM_DEALS.CONTACT.CREATE_ERROR')
    );
  } finally {
    isCreating.value = false;
  }
};
</script>

<template>
  <div class="flex flex-col gap-2">
    <div
      v-if="contact"
      class="flex items-center justify-between gap-2 px-3 py-2 border rounded-lg border-n-slate-6"
    >
      <div class="flex flex-col min-w-0">
        <span class="text-sm font-medium text-n-slate-12 truncate">
          {{ contact.name }}
        </span>
        <span class="text-label-small text-n-slate-11 truncate">
          {{ contact.phone_number || contact.email }}
        </span>
      </div>
      <Button
        icon="i-lucide-x"
        slate
        ghost
        xs
        :aria-label="t('CRM_DEALS.CONTACT.REMOVE')"
        @click="contact = null"
      />
    </div>
    <template v-else>
      <div class="relative">
        <span
          class="absolute i-lucide-search size-3.5 top-3 start-3 text-n-slate-10"
        />
        <input
          v-model="query"
          type="search"
          :placeholder="t('CRM_DEALS.CONTACT.SEARCH_PLACEHOLDER')"
          class="reset-base w-full h-10 ps-9 pe-3 text-sm rounded-lg border border-n-slate-6 bg-n-alpha-black2 text-n-slate-12 focus:outline-none focus:border-n-brand"
        />
      </div>
      <ul v-if="results.length" class="flex flex-col gap-1 p-0 m-0 list-none">
        <li v-for="item in results" :key="item.id">
          <button
            type="button"
            class="flex flex-col w-full px-3 py-2 text-start rounded-lg hover:bg-n-alpha-2"
            @click="select(item)"
          >
            <span class="text-sm text-n-slate-12">{{ item.name }}</span>
            <span class="text-label-small text-n-slate-11">
              {{ item.phone_number || item.email }}
            </span>
          </button>
        </li>
      </ul>
      <Button
        v-else-if="phoneCandidate && !isSearching"
        :label="t('CRM_DEALS.CONTACT.CREATE', { phone: phoneCandidate })"
        icon="i-lucide-user-plus"
        slate
        faded
        sm
        :is-loading="isCreating"
        @click="createByPhone"
      />
      <span
        v-else
        class="flex items-center gap-2 px-3 py-2 text-label-small border border-dashed rounded-lg border-n-slate-6 text-n-slate-11"
      >
        <span class="i-lucide-search size-3.5" />
        {{ t('CRM_DEALS.CONTACT.HINT') }}
      </span>
    </template>
  </div>
</template>
