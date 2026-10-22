<script setup>
import { computed, onMounted, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { useAdmin } from 'dashboard/composables/useAdmin';
import { useMapGetter, useStore } from 'dashboard/composables/store';
import { useCrmConversationStore } from 'dashboard/stores/crmConversation';
import Button from 'dashboard/components-next/button/Button.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import LossReasonModal from '../LossReasonModal.vue';
import ConversationDealCard from './ConversationDealCard.vue';
import CreateDealDialog from './CreateDealDialog.vue';

const props = defineProps({
  contactId: { type: Number, required: true },
  // Número de exibição da conversa, o mesmo da URL.
  conversationDisplayId: { type: [Number, String], required: true },
  contactBlocked: { type: Boolean, default: false },
});

// Ao bloquear, a perda automática dos deals roda em segundo plano (CCV2-15).
// O painel espera esse tempo antes de recarregar para já mostrar os deals perdidos.
const BLOCKED_RELOAD_DELAY_MS = 3000;

const { t } = useI18n();
const store = useStore();
const crm = useCrmConversationStore();
const { isAdmin } = useAdmin();
const agents = useMapGetter('agents/getVerifiedAgents');
const currentUserId = useMapGetter('getCurrentUserID');

const createDialogRef = ref(null);
const lossModalRef = ref(null);
const createError = ref('');
const showClosed = ref(false);
// Mudança para "Perdido" que espera o motivo.
const pendingLoss = ref(null);
const isSavingLoss = ref(false);

const hasPipelines = computed(() => crm.pipelines.length > 0);
const canCreate = computed(() => hasPipelines.value && !props.contactBlocked);

const runSafely = async action => {
  try {
    await action();
  } catch (error) {
    useAlert(error.message || t('CRM.CONVERSATION_PANEL.MESSAGES.LOAD_ERROR'));
  }
};

const loadPanel = () => runSafely(() => crm.fetchPanel(props.contactId));

const isCurrentConversation = deal =>
  String(deal.conversationDisplayId) === String(props.conversationDisplayId);

const onChangeStage = (deal, stageId) => {
  const stage = crm
    .pipelineById(deal.crmPipelineId)
    ?.stages.find(item => item.id === stageId);
  if (!stage || stageId === deal.crmStageId) return;

  if (stage.status === 'lost') {
    pendingLoss.value = { deal, stageId };
    lossModalRef.value?.open();
    return;
  }
  runSafely(() => crm.updateDeal(deal, { crm_stage_id: stageId }));
};

const onLossConfirm = async ({ lossReasonId, lossDetails }) => {
  const { deal, stageId } = pendingLoss.value;
  isSavingLoss.value = true;
  await runSafely(() =>
    crm.updateDeal(deal, {
      crm_stage_id: stageId,
      crm_loss_reason_id: lossReasonId,
      loss_details: lossDetails || null,
    })
  );
  isSavingLoss.value = false;
  pendingLoss.value = null;
  lossModalRef.value?.close();
};

const onLossCancel = () => {
  pendingLoss.value = null;
};

const onAssign = (deal, assigneeId) =>
  runSafely(() => crm.updateDeal(deal, { assignee_id: assigneeId }));

const openCreateDialog = () => {
  createError.value = '';
  createDialogRef.value?.open();
};

const onCreate = async attributes => {
  createError.value = '';
  try {
    await crm.createDeal({
      ...attributes,
      conversation_display_id: props.conversationDisplayId,
    });
    createDialogRef.value?.close();
    useAlert(t('CRM.CONVERSATION_PANEL.MESSAGES.CREATED'));
  } catch (error) {
    createError.value = error.message;
  }
};

watch(() => props.contactId, loadPanel);

watch(
  () => props.contactBlocked,
  (blocked, wasBlocked) => {
    if (blocked && !wasBlocked) {
      setTimeout(
        () => runSafely(() => crm.fetchDeals()),
        BLOCKED_RELOAD_DELAY_MS
      );
    }
  }
);

onMounted(() => {
  store.dispatch('agents/get');
  loadPanel();
});
</script>

<template>
  <div class="flex flex-col gap-3 p-3">
    <div class="flex items-center justify-between gap-2">
      <RouterLink
        :to="{ name: 'crm_kanban' }"
        class="inline-flex items-center gap-1 text-xs text-n-blue-11 hover:underline"
        data-test="view-in-pipeline"
      >
        <Icon icon="i-lucide-square-kanban" class="size-3.5" />
        {{ t('CRM.CONVERSATION_PANEL.VIEW_IN_PIPELINE') }}
      </RouterLink>
      <Button
        :label="t('CRM.CONVERSATION_PANEL.NEW_DEAL')"
        icon="i-lucide-plus"
        size="xs"
        variant="faded"
        :disabled="!canCreate"
        data-test="new-deal"
        @click="openCreateDialog"
      />
    </div>

    <p
      v-if="contactBlocked"
      class="flex items-start gap-1.5 p-2 text-xs rounded-lg bg-n-ruby-3 text-n-ruby-11"
      role="alert"
      data-test="blocked-alert"
    >
      <Icon icon="i-lucide-lock" class="size-3.5 shrink-0 mt-0.5" />
      {{ t('CRM.CONVERSATION_PANEL.BLOCKED') }}
    </p>

    <div v-if="crm.uiFlags.isFetching" class="flex justify-center py-4">
      <Spinner />
    </div>

    <div
      v-else-if="!hasPipelines"
      class="flex flex-col gap-1 text-xs text-n-slate-11"
      data-test="no-pipeline"
    >
      <p>
        {{
          isAdmin
            ? t('CRM.CONVERSATION_PANEL.NO_PIPELINE.ADMIN')
            : t('CRM.CONVERSATION_PANEL.NO_PIPELINE.AGENT')
        }}
      </p>
      <RouterLink
        v-if="isAdmin"
        :to="{ name: 'crm_settings_index' }"
        class="text-n-blue-11 hover:underline"
        data-test="settings-link"
      >
        {{ t('CRM.CONVERSATION_PANEL.NO_PIPELINE.SETTINGS_LINK') }}
      </RouterLink>
    </div>

    <template v-else>
      <p
        v-if="!crm.deals.length"
        class="text-xs text-n-slate-11"
        data-test="no-deals"
      >
        {{ t('CRM.CONVERSATION_PANEL.EMPTY') }}
      </p>
      <ConversationDealCard
        v-for="deal in crm.openDeals"
        :key="deal.id"
        :deal="deal"
        :pipeline="crm.pipelineById(deal.crmPipelineId)"
        :agents="agents"
        :is-current-conversation="isCurrentConversation(deal)"
        :locked="contactBlocked"
        @change-stage="stageId => onChangeStage(deal, stageId)"
        @assign="assigneeId => onAssign(deal, assigneeId)"
      />
      <button
        v-if="crm.closedDeals.length"
        type="button"
        class="self-start text-xs text-n-slate-11 hover:text-n-slate-12"
        data-test="toggle-closed"
        @click="showClosed = !showClosed"
      >
        {{
          showClosed
            ? t('CRM.CONVERSATION_PANEL.HIDE_CLOSED')
            : t('CRM.CONVERSATION_PANEL.SHOW_CLOSED', {
                count: crm.closedDeals.length,
              })
        }}
      </button>
      <template v-if="showClosed">
        <ConversationDealCard
          v-for="deal in crm.closedDeals"
          :key="deal.id"
          :deal="deal"
          :pipeline="crm.pipelineById(deal.crmPipelineId)"
          :agents="agents"
          :is-current-conversation="isCurrentConversation(deal)"
          :locked="contactBlocked"
          @change-stage="stageId => onChangeStage(deal, stageId)"
          @assign="assigneeId => onAssign(deal, assigneeId)"
        />
      </template>
    </template>

    <CreateDealDialog
      ref="createDialogRef"
      :pipelines="crm.pipelines"
      :default-pipeline-id="crm.defaultPipeline?.id"
      :agents="agents"
      :current-user-id="currentUserId"
      :is-loading="crm.uiFlags.isCreating"
      :error-message="createError"
      @create="onCreate"
    />
    <LossReasonModal
      ref="lossModalRef"
      :deal-title="pendingLoss?.deal.title"
      :loss-reasons="crm.lossReasons"
      :is-loading="isSavingLoss"
      @confirm="onLossConfirm"
      @cancel="onLossCancel"
    />
  </div>
</template>
