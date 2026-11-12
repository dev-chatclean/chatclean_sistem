<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import Avatar from 'dashboard/components-next/avatar/Avatar.vue';
import ReportCard from '../ReportCard.vue';
import ReportTable from '../ReportTable.vue';
import { formatCurrency } from '../../../dealHelpers';

// Desempenho por atendente: conversations of the period and the value won, ranked by volume and then revenue.
const props = defineProps({
  agents: { type: Array, required: true },
});

const { t } = useI18n();

const rows = computed(() =>
  props.agents
    .map(agent => ({ ...agent, key: agent.id }))
    .sort(
      (a, b) => b.conversations - a.conversations || b.won_value - a.won_value
    )
);
</script>

<template>
  <ReportCard
    :title="t('CRM_REPORTS.OVERVIEW.AGENTS.TITLE')"
    :description="t('CRM_REPORTS.OVERVIEW.AGENTS.DESCRIPTION')"
  >
    <p v-if="!rows.length" class="py-6 text-sm text-center text-n-slate-11">
      {{ t('CRM_REPORTS.OVERVIEW.AGENTS.EMPTY') }}
    </p>
    <ReportTable
      v-else
      :columns="[
        t('CRM_REPORTS.OVERVIEW.AGENTS.AGENT'),
        t('CRM_REPORTS.OVERVIEW.AGENTS.CONVERSATIONS'),
        t('CRM_REPORTS.OVERVIEW.AGENTS.WON_VALUE'),
      ]"
      :rows="rows"
    >
      <template #row="{ row }">
        <td class="px-2.5 py-2.5">
          <span class="flex items-center gap-2 text-n-slate-12">
            <Avatar
              :name="row.name"
              :src="row.thumbnail"
              :size="22"
              rounded-full
            />
            <span class="truncate">{{ row.name }}</span>
          </span>
        </td>
        <td class="px-2.5 py-2.5 text-end text-n-slate-12">
          {{ row.conversations }}
        </td>
        <td class="px-2.5 py-2.5 text-end text-n-teal-11 whitespace-nowrap">
          {{
            row.won_value
              ? formatCurrency(row.won_value)
              : t('CRM_REPORTS.SALES.NO_DATA')
          }}
        </td>
      </template>
    </ReportTable>
  </ReportCard>
</template>
