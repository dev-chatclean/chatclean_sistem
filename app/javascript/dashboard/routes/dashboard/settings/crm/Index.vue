<script setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRoute, useRouter } from 'vue-router';
import BaseSettingsHeader from '../components/BaseSettingsHeader.vue';
import SettingsLayout from '../SettingsLayout.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import TabBar from 'dashboard/components-next/tabbar/TabBar.vue';
import PipelinesTab from './PipelinesTab.vue';
import LossReasonsTab from './LossReasonsTab.vue';

const TABS = ['pipelines', 'loss_reasons'];

const { t } = useI18n();
const route = useRoute();
const router = useRouter();

// A aba ativa fica na URL (?tab=), começando em funis (CA 9.1).
const activeTab = computed(() =>
  TABS.includes(route.query.tab) ? route.query.tab : TABS[0]
);

const tabs = computed(() => [
  { key: 'pipelines', label: t('CRM.SETTINGS.TABS.PIPELINES') },
  { key: 'loss_reasons', label: t('CRM.SETTINGS.TABS.LOSS_REASONS') },
]);

const onTabChanged = tab => {
  router.replace({ query: { ...route.query, tab: tab.key } });
};

const tabRef = ref(null);
</script>

<template>
  <SettingsLayout>
    <template #header>
      <BaseSettingsHeader
        :title="t('CRM.SETTINGS.HEADER')"
        :description="t('CRM.SETTINGS.DESCRIPTION')"
      >
        <template #tabs>
          <TabBar
            :tabs="tabs"
            :initial-active-tab="TABS.indexOf(activeTab)"
            @tab-changed="onTabChanged"
          />
        </template>
        <template #actions>
          <Button
            :label="
              activeTab === 'pipelines'
                ? t('CRM.SETTINGS.PIPELINES.NEW')
                : t('CRM.SETTINGS.LOSS_REASONS.NEW')
            "
            icon="i-lucide-plus"
            size="sm"
            data-test="create"
            @click="tabRef?.openCreate()"
          />
        </template>
      </BaseSettingsHeader>
    </template>
    <template #body>
      <PipelinesTab v-if="activeTab === 'pipelines'" ref="tabRef" />
      <LossReasonsTab v-else ref="tabRef" />
    </template>
  </SettingsLayout>
</template>
