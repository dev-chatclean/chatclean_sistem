<script setup>
import { ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import CrmDealsAPI from 'dashboard/api/crm/deals';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import { formatCurrency } from '../../../dealHelpers';

const props = defineProps({
  deal: { type: Object, required: true },
});

const emit = defineEmits(['open']);

const { t } = useI18n();

const deals = ref([]);
const isLoading = ref(false);

const load = async () => {
  deals.value = [];
  if (!props.deal.contact) return;
  isLoading.value = true;
  try {
    const { data } = await CrmDealsAPI.forContact(props.deal.contact.id);
    deals.value = data.payload.filter(item => item.id !== props.deal.id);
  } finally {
    isLoading.value = false;
  }
};

watch(() => props.deal.contact?.id, load, { immediate: true });
</script>

<template>
  <p v-if="!deal.contact" class="py-6 text-base text-center text-n-slate-11">
    {{ t('CRM_DEALS.DETAIL.DEALS_NEED_CONTACT') }}
  </p>
  <div v-else-if="isLoading" class="flex justify-center py-6"><Spinner /></div>
  <p
    v-else-if="!deals.length"
    class="py-6 text-base text-center text-n-slate-11"
  >
    {{ t('CRM_DEALS.DETAIL.NO_OTHER_DEALS') }}
  </p>
  <ul v-else class="flex flex-col gap-2 p-0 m-0 list-none">
    <li v-for="item in deals" :key="item.id">
      <button
        type="button"
        class="flex items-center justify-between w-full gap-3 px-4 py-3 text-start border rounded-xl border-n-weak hover:bg-n-alpha-1"
        @click="emit('open', item)"
      >
        <span class="flex flex-col min-w-0">
          <span class="text-sm font-medium text-n-slate-12 truncate">
            {{ t('CRM_DEALS.NUMBER', { number: item.number }) }} ·
            {{ item.display_name }}
          </span>
          <span
            class="flex items-center gap-1.5 text-label-small text-n-slate-11"
          >
            <span
              class="rounded-full size-2"
              :style="{ backgroundColor: item.stage_color }"
            />
            {{ item.pipeline_name }} · {{ item.stage_name }}
          </span>
        </span>
        <span class="text-sm font-medium text-n-slate-12 shrink-0">
          {{ formatCurrency(item.value) }}
        </span>
      </button>
    </li>
  </ul>
</template>
