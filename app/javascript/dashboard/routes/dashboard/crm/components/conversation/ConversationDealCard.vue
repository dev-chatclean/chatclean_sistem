<script setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import Select from 'dashboard/components-next/select/Select.vue';
import AssigneePicker from '../AssigneePicker.vue';
import { formatCurrency } from '../../helpers/currency';

const props = defineProps({
  deal: { type: Object, required: true },
  pipeline: { type: Object, default: null },
  agents: { type: Array, default: () => [] },
  isCurrentConversation: { type: Boolean, default: false },
  locked: { type: Boolean, default: false },
});

const emit = defineEmits(['changeStage', 'assign']);

const { t } = useI18n();

const stageOptions = computed(() =>
  (props.pipeline?.stages || []).map(stage => ({
    value: stage.id,
    label: stage.name,
  }))
);

const stageName = computed(
  () =>
    props.pipeline?.stages.find(stage => stage.id === props.deal.crmStageId)
      ?.name
);

// O seletor sempre mostra o estágio salvo. Trocar o key recria o <select> nativo,
// que volta ao estágio atual se o modal de perda for cancelado ou a API recusar.
const stageSelectKey = ref(0);
const onStageSelect = stageId => {
  stageSelectKey.value += 1;
  emit('changeStage', Number(stageId));
};
</script>

<template>
  <article
    class="flex flex-col gap-2 p-3 rounded-lg outline outline-1 outline-n-weak bg-n-solid-1"
    :data-deal-id="deal.id"
  >
    <div class="flex items-start justify-between gap-2">
      <h4 class="text-sm font-medium break-words text-n-slate-12 line-clamp-2">
        {{ deal.title }}
      </h4>
      <span
        v-if="isCurrentConversation"
        class="px-1.5 text-xs rounded-md shrink-0 bg-n-blue-3 text-n-blue-11"
        data-test="current-conversation"
      >
        {{ t('CRM.CONVERSATION_PANEL.CARD.THIS_CONVERSATION') }}
      </span>
    </div>
    <span class="text-sm font-semibold tabular-nums text-n-slate-12">
      {{ formatCurrency(deal.value) }}
    </span>
    <span class="text-xs truncate text-n-slate-11" data-test="pipeline-stage">
      {{
        t('CRM.CONVERSATION_PANEL.CARD.PIPELINE_STAGE', {
          pipeline: pipeline?.name,
          stage: stageName,
        })
      }}
    </span>
    <Select
      :key="stageSelectKey"
      :model-value="deal.crmStageId"
      :options="stageOptions"
      :disabled="locked"
      :aria-label="t('CRM.CONVERSATION_PANEL.CARD.STAGE_LABEL')"
      class="!w-full [&>select]:w-full"
      data-test="stage-select"
      @update:model-value="onStageSelect"
    />
    <AssigneePicker
      :deal="deal"
      :agents="agents"
      :disabled="locked"
      @assign="assigneeId => emit('assign', assigneeId)"
    />
  </article>
</template>
