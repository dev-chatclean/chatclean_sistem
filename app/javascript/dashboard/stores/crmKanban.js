import camelcaseKeys from 'camelcase-keys';
import { defineStore } from 'pinia';
import CrmDealsAPI from 'dashboard/api/crm/deals';
import CrmPipelinesAPI from 'dashboard/api/crm/pipelines';
import CrmLossReasonsAPI from 'dashboard/api/crm/lossReasons';
import { throwErrorMessage } from 'dashboard/store/utils/api';

// Mesmo tamanho de página da API de deals (RESULTS_PER_PAGE).
export const DEALS_PER_PAGE = 50;

const toCamel = data => camelcaseKeys(data, { deep: true });

const emptyColumn = () => ({
  deals: [],
  page: 0,
  hasMore: true,
  isLoading: false,
});

export const useCrmKanbanStore = defineStore('crmKanban', {
  state: () => ({
    pipelines: [],
    selectedPipelineId: null,
    // "" (todos), "none" (sem responsável) ou o id de um agente.
    assigneeFilter: '',
    columns: {},
    summary: {},
    lossReasons: [],
    uiFlags: { isFetchingPipelines: false },
  }),
  getters: {
    selectedPipeline: state =>
      state.pipelines.find(
        pipeline => pipeline.id === state.selectedPipelineId
      ),
    stages() {
      return this.selectedPipeline?.stages || [];
    },
    openStages() {
      return this.stages.filter(stage => stage.status === 'open');
    },
    closingStages() {
      return this.stages.filter(stage => stage.status !== 'open');
    },
  },
  actions: {
    async fetchPipelines() {
      this.uiFlags.isFetchingPipelines = true;
      try {
        const { data } = await CrmPipelinesAPI.get();
        this.pipelines = toCamel(data.payload);
        const stillExists = this.pipelines.some(
          pipeline => pipeline.id === this.selectedPipelineId
        );
        if (!stillExists) {
          // Abre no padrão; sem padrão, no primeiro (CCV2-15).
          const initial =
            this.pipelines.find(pipeline => pipeline.isDefault) ||
            this.pipelines[0];
          this.selectedPipelineId = initial?.id || null;
        }
      } catch (error) {
        throwErrorMessage(error);
      } finally {
        this.uiFlags.isFetchingPipelines = false;
      }
    },

    async loadBoard() {
      this.columns = Object.fromEntries(
        this.stages.map(stage => [stage.id, emptyColumn()])
      );
      await Promise.all([
        ...this.stages.map(stage => this.fetchColumn(stage.id)),
        this.fetchSummary(),
      ]);
    },

    async selectPipeline(pipelineId) {
      this.selectedPipelineId = pipelineId;
      await this.loadBoard();
    },

    async setAssigneeFilter(value) {
      this.assigneeFilter = value;
      await this.loadBoard();
    },

    filterParams() {
      return this.assigneeFilter ? { assignee_id: this.assigneeFilter } : {};
    },

    async fetchColumn(stageId) {
      const column = this.columns[stageId];
      if (!column || column.isLoading || !column.hasMore) return;

      column.isLoading = true;
      try {
        const { data } = await CrmDealsAPI.get({
          crm_stage_id: stageId,
          page: column.page + 1,
          ...this.filterParams(),
        });
        const deals = toCamel(data.payload);
        column.deals.push(
          ...deals.filter(
            deal => !column.deals.some(existing => existing.id === deal.id)
          )
        );
        column.page += 1;
        column.hasMore = deals.length === DEALS_PER_PAGE;
      } catch (error) {
        throwErrorMessage(error);
      } finally {
        column.isLoading = false;
      }
    },

    async fetchSummary() {
      if (!this.selectedPipelineId) return;
      const { data } = await CrmPipelinesAPI.summary(
        this.selectedPipelineId,
        this.filterParams()
      );
      this.summary = Object.fromEntries(
        toCamel(data.payload).map(item => [
          item.crmStageId,
          { dealsCount: item.dealsCount, totalValue: Number(item.totalValue) },
        ])
      );
    },

    async fetchLossReasons() {
      const { data } = await CrmLossReasonsAPI.getActive();
      this.lossReasons = toCamel(data.payload);
    },

    // O card já foi colocado na coluna de destino pelo arraste (atualização otimista).
    // Se a API recusar, ele volta para a coluna e posição de origem.
    async moveDeal({ deal, toStageId, origin, lossReasonId, lossDetails }) {
      const payload = { crm_stage_id: toStageId };
      if (lossReasonId) {
        payload.crm_loss_reason_id = lossReasonId;
        payload.loss_details = lossDetails || null;
      }
      try {
        const { data } = await CrmDealsAPI.update(deal.id, { deal: payload });
        this.replaceDeal(toStageId, toCamel(data.payload));
        this.fetchSummary();
      } catch (error) {
        this.revertMove({ deal, toStageId, origin });
        throwErrorMessage(error);
      }
    },

    revertMove({ deal, toStageId, origin }) {
      const target = this.columns[toStageId];
      if (target)
        target.deals = target.deals.filter(item => item.id !== deal.id);
      const source = this.columns[origin.stageId];
      if (source && !source.deals.some(item => item.id === deal.id)) {
        source.deals.splice(origin.index, 0, deal);
      }
    },

    replaceDeal(stageId, updated) {
      const column = this.columns[stageId];
      if (!column) return;
      const index = column.deals.findIndex(item => item.id === updated.id);
      if (index !== -1) column.deals.splice(index, 1, updated);
    },

    async assignDeal(deal, assigneeId) {
      try {
        const { data } = await CrmDealsAPI.update(deal.id, {
          deal: { assignee_id: assigneeId },
        });
        this.replaceDeal(deal.crmStageId, toCamel(data.payload));
        this.fetchSummary();
      } catch (error) {
        throwErrorMessage(error);
      }
    },

    // Recebe só os estágios abertos; Ganho e Perdido ficam sempre no fim.
    async reorderStages(openStageIds) {
      const pipeline = this.selectedPipeline;
      const previous = pipeline.stages;
      const byId = Object.fromEntries(previous.map(stage => [stage.id, stage]));
      pipeline.stages = [
        ...openStageIds.map(id => byId[id]),
        ...this.closingStages,
      ];
      try {
        const { data } = await CrmPipelinesAPI.reorderStages(
          pipeline.id,
          openStageIds
        );
        pipeline.stages = toCamel(data.payload);
      } catch (error) {
        pipeline.stages = previous;
        throwErrorMessage(error);
      }
    },
  },
});
