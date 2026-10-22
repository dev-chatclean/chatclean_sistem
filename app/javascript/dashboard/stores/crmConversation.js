import camelcaseKeys from 'camelcase-keys';
import { defineStore } from 'pinia';
import CrmDealsAPI from 'dashboard/api/crm/deals';
import CrmPipelinesAPI from 'dashboard/api/crm/pipelines';
import CrmLossReasonsAPI from 'dashboard/api/crm/lossReasons';
import { throwErrorMessage } from 'dashboard/store/utils/api';

const toCamel = data => camelcaseKeys(data, { deep: true });

const byRecentUpdate = (a, b) => b.updatedAt - a.updatedAt;

// Deals do contato aberto no painel lateral da conversa (CCV2-16).
export const useCrmConversationStore = defineStore('crmConversation', {
  state: () => ({
    contactId: null,
    deals: [],
    pipelines: [],
    lossReasons: [],
    uiFlags: { isFetching: false, isCreating: false },
  }),
  getters: {
    openDeals: state =>
      state.deals.filter(deal => deal.status === 'open').sort(byRecentUpdate),
    closedDeals: state =>
      state.deals.filter(deal => deal.status !== 'open').sort(byRecentUpdate),
    defaultPipeline: state =>
      state.pipelines.find(pipeline => pipeline.isDefault) ||
      state.pipelines[0],
    pipelineById: state => id =>
      state.pipelines.find(pipeline => pipeline.id === id),
  },
  actions: {
    async fetchPanel(contactId) {
      this.contactId = contactId;
      this.deals = [];
      this.uiFlags.isFetching = true;
      try {
        await Promise.all([this.fetchDeals(), this.fetchSettings()]);
      } finally {
        this.uiFlags.isFetching = false;
      }
    },

    async fetchDeals() {
      const contactId = this.contactId;
      try {
        const { data } = await CrmDealsAPI.get({ contact_id: contactId });
        // A conversa pode ter mudado enquanto a resposta chegava.
        if (contactId === this.contactId) this.deals = toCamel(data.payload);
      } catch (error) {
        throwErrorMessage(error);
      }
    },

    async fetchSettings() {
      try {
        const [pipelines, lossReasons] = await Promise.all([
          CrmPipelinesAPI.get(),
          CrmLossReasonsAPI.getActive(),
        ]);
        this.pipelines = toCamel(pipelines.data.payload);
        this.lossReasons = toCamel(lossReasons.data.payload);
      } catch (error) {
        throwErrorMessage(error);
      }
    },

    async createDeal(attributes) {
      this.uiFlags.isCreating = true;
      try {
        const { data } = await CrmDealsAPI.create({ deal: attributes });
        this.deals.unshift(toCamel(data.payload));
      } catch (error) {
        throwErrorMessage(error);
      } finally {
        this.uiFlags.isCreating = false;
      }
    },

    async updateDeal(deal, attributes) {
      try {
        const { data } = await CrmDealsAPI.update(deal.id, {
          deal: attributes,
        });
        const updated = toCamel(data.payload);
        const index = this.deals.findIndex(item => item.id === updated.id);
        if (index !== -1) this.deals.splice(index, 1, updated);
      } catch (error) {
        throwErrorMessage(error);
      }
    },
  },
});
