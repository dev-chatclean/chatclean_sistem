<script setup>
import { computed, onMounted, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRouter } from 'vue-router';
import { useAlert } from 'dashboard/composables';
import { useAdmin } from 'dashboard/composables/useAdmin';
import { useStore } from 'dashboard/composables/store';
import CrmDealsAPI from 'dashboard/api/crm/deals';
import CrmPipelinesAPI from 'dashboard/api/crm/pipelines';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import DealFormDialog from '../deals/DealFormDialog.vue';
import { formatCurrency } from '../../dealHelpers';
import { useItemLabel } from '../../useItemLabel';

const props = defineProps({
  contact: { type: Object, required: true },
});

const STATUS_DOT = {
  open: 'bg-n-blue-9',
  won: 'bg-n-teal-9',
  lost: 'bg-n-ruby-9',
};

const { t } = useI18n();
const router = useRouter();
const { itemLabel } = useItemLabel();
const { isAdmin } = useAdmin();
const store = useStore();

const deals = ref([]);
const pipelines = ref([]);
const pipelineId = ref(null);
const isLoading = ref(false);
const dealFormRef = ref(null);

const selectedPipeline = computed(() =>
  pipelines.value.find(pipeline => pipeline.id === pipelineId.value)
);

const loadDeals = async () => {
  isLoading.value = true;
  try {
    const { data } = await CrmDealsAPI.forContact(props.contact.id);
    deals.value = data.payload;
  } catch (error) {
    useAlert(t('CRM_DEALS.API.FETCH_ERROR'));
  } finally {
    isLoading.value = false;
  }
};

const loadPipelines = async () => {
  const { data } = await CrmPipelinesAPI.get();
  pipelines.value = data.payload;
  pipelineId.value = (
    data.payload.find(pipeline => pipeline.is_default) || data.payload[0]
  )?.id;
};

const openDeal = deal =>
  router.push({
    name: 'crm_pipelines_show',
    params: { pipelineId: deal.pipeline_id },
    query: { deal: deal.id },
  });

const openNewDeal = () => dealFormRef.value?.open({ contact: props.contact });

watch(() => props.contact.id, loadDeals);

onMounted(() => {
  if (isAdmin.value) store.dispatch('agents/get');
  loadDeals();
  loadPipelines();
});
</script>

<template>
  <div class="flex flex-col gap-4 px-6 pb-6">
    <div v-if="pipelines.length" class="flex gap-2">
      <select
        v-model="pipelineId"
        class="reset-base flex-1 min-w-0 h-9 px-3 text-sm rounded-lg border border-n-slate-6 bg-n-alpha-black2 text-n-slate-12"
        :aria-label="t('CRM_DEALS.CONTACT_TAB.PIPELINE')"
      >
        <option
          v-for="pipeline in pipelines"
          :key="pipeline.id"
          :value="pipeline.id"
        >
          {{ pipeline.name }}
        </option>
      </select>
      <button
        type="button"
        class="flex items-center gap-1.5 h-9 px-3 text-sm font-medium rounded-lg outline outline-1 -outline-offset-1 outline-n-slate-6 text-n-slate-12 hover:bg-n-alpha-1 shrink-0"
        @click="openNewDeal"
      >
        <span class="i-lucide-plus size-4" />
        {{ t('CRM_DEALS.CONTACT_TAB.NEW') }}
      </button>
    </div>

    <div v-if="isLoading" class="flex justify-center py-6"><Spinner /></div>
    <p
      v-else-if="!deals.length"
      class="py-6 text-sm text-center text-n-slate-11"
    >
      {{ t('CRM_DEALS.CONTACT_TAB.EMPTY') }}
    </p>
    <ul v-else class="flex flex-col gap-2 p-0 m-0 list-none">
      <li v-for="deal in deals" :key="deal.id">
        <button
          type="button"
          class="flex flex-col w-full gap-1.5 px-4 py-3 text-start rounded-xl outline outline-1 -outline-offset-1 outline-n-weak hover:bg-n-alpha-1"
          @click="openDeal(deal)"
        >
          <span class="flex items-center justify-between gap-3">
            <span class="text-sm font-medium truncate text-n-slate-12">
              {{ t('CRM_DEALS.NUMBER', { number: deal.number }) }} ·
              {{ deal.display_name }}
            </span>
            <span class="text-sm font-medium text-n-slate-12 shrink-0">
              {{ formatCurrency(deal.value) }}
            </span>
          </span>
          <span
            class="flex items-center gap-1.5 text-label-small text-n-slate-11"
          >
            <span
              class="rounded-full size-2 shrink-0"
              :class="STATUS_DOT[deal.status]"
            />
            {{ t(`CRM_DEALS.STATUS.${deal.status.toUpperCase()}`) }} ·
            {{ deal.pipeline_name }} · {{ deal.stage_name }}
          </span>
          <span
            class="flex items-center gap-1 text-label-small text-n-slate-11"
          >
            <span class="i-lucide-user size-3.5" />
            {{ deal.assignee.name }}
          </span>
        </button>
      </li>
    </ul>

    <DealFormDialog
      v-if="selectedPipeline"
      ref="dealFormRef"
      :pipeline="selectedPipeline"
      :item-label="itemLabel(selectedPipeline)"
      @created="loadDeals"
    />
  </div>
</template>
