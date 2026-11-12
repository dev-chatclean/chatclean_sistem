<script setup>
import { ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { debounce } from '@chatwoot/utils';
import CompanyAPI from 'dashboard/api/companies';
import Button from 'dashboard/components-next/button/Button.vue';
import { SEARCH_DEBOUNCE_MS } from '../../constants';

const company = defineModel({ type: Object, default: null });

const { t } = useI18n();

const MAX_RESULTS = 6;

const query = ref('');
const results = ref([]);

const search = debounce(async value => {
  if (!value.trim()) {
    results.value = [];
    return;
  }
  try {
    const { data } = await CompanyAPI.search(value.trim());
    results.value = data.payload.slice(0, MAX_RESULTS);
  } catch (error) {
    results.value = [];
  }
}, SEARCH_DEBOUNCE_MS);

watch(query, search);

const select = item => {
  company.value = { id: item.id, name: item.name };
  query.value = '';
  results.value = [];
};
</script>

<template>
  <div class="flex flex-col gap-2">
    <div
      v-if="company"
      class="flex items-center justify-between gap-2 px-3 py-2 rounded-lg outline outline-1 -outline-offset-1 outline-n-slate-6"
    >
      <span class="flex items-center gap-2 min-w-0 text-sm text-n-slate-12">
        <span class="i-lucide-building-2 size-4 shrink-0 text-n-slate-11" />
        <span class="truncate">{{ company.name }}</span>
      </span>
      <Button
        icon="i-lucide-x"
        slate
        ghost
        xs
        :aria-label="t('CRM_DEALS.COMPANY.REMOVE')"
        @click="company = null"
      />
    </div>
    <template v-else>
      <div class="relative">
        <span
          class="absolute i-lucide-building-2 size-3.5 top-3 start-3 text-n-slate-10"
        />
        <input
          v-model="query"
          type="search"
          :placeholder="t('CRM_DEALS.COMPANY.SEARCH_PLACEHOLDER')"
          class="reset-base w-full h-10 ps-9 pe-3 text-sm rounded-lg border border-n-slate-6 bg-n-alpha-black2 text-n-slate-12 focus:outline-none focus:border-n-brand"
        />
      </div>
      <ul v-if="results.length" class="flex flex-col gap-1 p-0 m-0 list-none">
        <li v-for="item in results" :key="item.id">
          <button
            type="button"
            class="flex w-full px-3 py-2 text-sm text-start rounded-lg text-n-slate-12 hover:bg-n-alpha-2"
            @click="select(item)"
          >
            {{ item.name }}
          </button>
        </li>
      </ul>
      <p
        v-else-if="query.trim()"
        class="m-0 px-1 text-label-small text-n-slate-11"
      >
        {{ t('CRM_DEALS.COMPANY.NO_RESULTS') }}
      </p>
    </template>
  </div>
</template>
