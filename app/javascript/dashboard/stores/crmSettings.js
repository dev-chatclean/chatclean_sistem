import camelcaseKeys from 'camelcase-keys';
import { defineStore } from 'pinia';
import CrmPipelinesAPI from 'dashboard/api/crm/pipelines';
import CrmLossReasonsAPI from 'dashboard/api/crm/lossReasons';
import { throwErrorMessage } from 'dashboard/store/utils/api';

const toCamel = data => camelcaseKeys(data, { deep: true });

// Tela de configurações do CRM: funis com estágios e motivos de perda (CCV2-17).
// As actions lançam o erro já traduzido pela API para a tela mostrar.
export const useCrmSettingsStore = defineStore('crmSettings', {
  state: () => ({
    pipelines: [],
    lossReasons: [],
    uiFlags: { isFetchingPipelines: false, isFetchingLossReasons: false },
  }),
  getters: {
    defaultPipeline: state =>
      state.pipelines.find(pipeline => pipeline.isDefault),
  },
  actions: {
    async request(action) {
      try {
        return await action();
      } catch (error) {
        return throwErrorMessage(error);
      }
    },

    async fetchPipelines() {
      this.uiFlags.isFetchingPipelines = true;
      try {
        await this.request(async () => {
          const { data } = await CrmPipelinesAPI.get();
          this.pipelines = toCamel(data.payload);
        });
      } finally {
        this.uiFlags.isFetchingPipelines = false;
      }
    },

    // Recarrega um funil depois de mexer nos estágios: a API recalcula as posições.
    async refreshPipeline(pipelineId) {
      const { data } = await CrmPipelinesAPI.show(pipelineId);
      const updated = toCamel(data.payload);
      this.pipelines = this.pipelines.map(pipeline =>
        pipeline.id === updated.id ? updated : pipeline
      );
    },

    async createPipeline(attributes) {
      const pipeline = await this.request(async () => {
        const { data } = await CrmPipelinesAPI.create({ pipeline: attributes });
        return toCamel(data.payload);
      });
      // Marcar como padrão desmarca o anterior no servidor; a lista acompanha.
      await this.fetchPipelines();
      return pipeline;
    },

    async updatePipeline(pipelineId, attributes) {
      await this.request(() =>
        CrmPipelinesAPI.update(pipelineId, { pipeline: attributes })
      );
      await this.fetchPipelines();
    },

    async deletePipeline(pipelineId) {
      await this.request(() => CrmPipelinesAPI.delete(pipelineId));
      this.pipelines = this.pipelines.filter(
        pipeline => pipeline.id !== pipelineId
      );
    },

    async createStage(pipelineId, attributes) {
      await this.request(() =>
        CrmPipelinesAPI.createStage(pipelineId, attributes)
      );
      await this.refreshPipeline(pipelineId);
    },

    async updateStage(pipelineId, stageId, attributes) {
      await this.request(() =>
        CrmPipelinesAPI.updateStage(pipelineId, stageId, attributes)
      );
      await this.refreshPipeline(pipelineId);
    },

    async deleteStage(pipelineId, stageId) {
      await this.request(() =>
        CrmPipelinesAPI.deleteStage(pipelineId, stageId)
      );
      await this.refreshPipeline(pipelineId);
    },

    // Otimista: a nova ordem aparece na hora e volta se a API recusar (FA 9.2).
    async reorderStages(pipelineId, openStageIds) {
      const pipeline = this.pipelines.find(item => item.id === pipelineId);
      const previous = pipeline.stages;
      const byId = Object.fromEntries(previous.map(stage => [stage.id, stage]));
      pipeline.stages = [
        ...openStageIds.map(id => byId[id]),
        ...previous.filter(stage => stage.status !== 'open'),
      ];
      try {
        const { data } = await CrmPipelinesAPI.reorderStages(
          pipelineId,
          openStageIds
        );
        pipeline.stages = toCamel(data.payload);
      } catch (error) {
        pipeline.stages = previous;
        throwErrorMessage(error);
      }
    },

    async fetchLossReasons() {
      this.uiFlags.isFetchingLossReasons = true;
      try {
        await this.request(async () => {
          const { data } = await CrmLossReasonsAPI.get();
          this.lossReasons = toCamel(data.payload);
        });
      } finally {
        this.uiFlags.isFetchingLossReasons = false;
      }
    },

    async createLossReason(attributes) {
      await this.request(() =>
        CrmLossReasonsAPI.create({ loss_reason: attributes })
      );
      await this.fetchLossReasons();
    },

    async updateLossReason(lossReasonId, attributes) {
      const updated = await this.request(async () => {
        const { data } = await CrmLossReasonsAPI.update(lossReasonId, {
          loss_reason: attributes,
        });
        return toCamel(data.payload);
      });
      this.lossReasons = this.lossReasons.map(reason =>
        reason.id === updated.id ? updated : reason
      );
    },
  },
});
