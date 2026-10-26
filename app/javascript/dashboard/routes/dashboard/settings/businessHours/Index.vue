<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRoute, useRouter } from 'vue-router';
import BaseSettingsHeader from '../components/BaseSettingsHeader.vue';
import SettingsLayout from '../SettingsLayout.vue';
import TabBar from 'dashboard/components-next/tabbar/TabBar.vue';
import ScheduleTab from './ScheduleTab.vue';
import HolidaysTab from './HolidaysTab.vue';

const TABS = ['schedule', 'holidays'];

const { t } = useI18n();
const route = useRoute();
const router = useRouter();

// A aba ativa fica na URL (?tab=), começando no horário.
const activeTab = computed(() =>
  TABS.includes(route.query.tab) ? route.query.tab : TABS[0]
);
const tabs = computed(() => [
  { key: 'schedule', label: t('CHATCLEAN.BUSINESS_HOURS.TABS.SCHEDULE') },
  { key: 'holidays', label: t('CHATCLEAN.BUSINESS_HOURS.TABS.HOLIDAYS') },
]);

const onTabChanged = tab => {
  router.replace({ query: { ...route.query, tab: tab.key } });
};
</script>

<template>
  <SettingsLayout>
    <template #header>
      <BaseSettingsHeader
        :title="t('CHATCLEAN.BUSINESS_HOURS.HEADER')"
        :description="t('CHATCLEAN.BUSINESS_HOURS.DESCRIPTION')"
      >
        <template #tabs>
          <TabBar
            :tabs="tabs"
            :initial-active-tab="TABS.indexOf(activeTab)"
            @tab-changed="onTabChanged"
          />
        </template>
      </BaseSettingsHeader>
    </template>
    <template #body>
      <ScheduleTab v-if="activeTab === 'schedule'" />
      <HolidaysTab v-else />
    </template>
  </SettingsLayout>
</template>
