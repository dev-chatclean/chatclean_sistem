<script setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useIntersectionObserver } from '@vueuse/core';
import Draggable from 'vuedraggable';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import DealCard from './DealCard.vue';

const props = defineProps({
  stage: { type: Object, required: true },
  column: { type: Object, required: true },
  summary: { type: Object, default: () => ({ dealsCount: 0, totalValue: 0 }) },
  agents: { type: Array, default: () => [] },
  canReorder: { type: Boolean, default: false },
});

const emit = defineEmits(['dragStart', 'dealAdded', 'loadMore', 'assign']);

const { t } = useI18n();
const currency = new Intl.NumberFormat('pt-BR', {
  style: 'currency',
  currency: 'BRL',
});

const formattedTotal = computed(() =>
  currency.format(props.summary.totalValue || 0)
);
const accentClass = computed(
  () =>
    ({ won: 'bg-n-teal-9', lost: 'bg-n-ruby-9' })[props.stage.status] ||
    'bg-n-blue-9'
);

// Contato bloqueado não sai do lugar: o deal já foi perdido e fica travado (CCV2-15).
const canMove = ({ draggedContext }) =>
  !draggedContext.element.contact?.blocked;

const onStart = ({ oldIndex }) =>
  emit('dragStart', { stageId: props.stage.id, index: oldIndex });

const onChange = ({ added }) => {
  if (added) emit('dealAdded', { deal: added.element, stage: props.stage });
};

const sentinel = ref(null);
useIntersectionObserver(sentinel, ([entry]) => {
  if (entry?.isIntersecting && props.column.hasMore && !props.column.isLoading)
    emit('loadMore');
});
</script>

<template>
  <section
    class="flex flex-col w-72 shrink-0 max-h-full rounded-xl bg-n-alpha-1"
    :data-stage-id="stage.id"
  >
    <header class="flex flex-col gap-1 px-3 pt-3 pb-2">
      <div class="flex items-center gap-2 min-w-0">
        <Icon
          v-if="canReorder"
          icon="i-lucide-grip-vertical"
          class="stage-handle size-4 shrink-0 cursor-grab text-n-slate-10"
          :title="t('CRM.KANBAN.COLUMN.DRAG_TO_REORDER')"
        />
        <span class="size-2 rounded-full shrink-0" :class="accentClass" />
        <h3 class="text-sm font-medium truncate text-n-slate-12">
          {{ stage.name }}
        </h3>
        <span class="ml-auto text-xs shrink-0 text-n-slate-10">
          {{
            t('CRM.KANBAN.COLUMN.PROBABILITY', {
              probability: stage.probability,
            })
          }}
        </span>
      </div>
      <div class="flex items-center justify-between text-xs text-n-slate-11">
        <span>{{
          t('CRM.KANBAN.COLUMN.DEALS_COUNT', { count: summary.dealsCount })
        }}</span>
        <span class="font-medium tabular-nums">{{ formattedTotal }}</span>
      </div>
    </header>
    <div class="flex-1 min-h-0 px-2 pb-2 overflow-y-auto">
      <Draggable
        :list="column.deals"
        group="crm-deals"
        item-key="id"
        :sort="false"
        :move="canMove"
        filter="a, button"
        :prevent-on-filter="false"
        class="flex flex-col gap-2 min-h-16"
        @start="onStart"
        @change="onChange"
      >
        <template #item="{ element }">
          <DealCard
            :deal="element"
            :agents="agents"
            @assign="assigneeId => emit('assign', element, assigneeId)"
          />
        </template>
      </Draggable>
      <p
        v-if="!column.deals.length && !column.isLoading"
        class="px-2 py-6 text-xs text-center text-n-slate-10"
      >
        {{ t('CRM.KANBAN.COLUMN.EMPTY') }}
      </p>
      <div
        v-if="column.isLoading"
        class="flex justify-center py-3"
        :aria-label="t('CRM.KANBAN.COLUMN.LOADING')"
      >
        <Spinner />
      </div>
      <div ref="sentinel" class="h-px" />
    </div>
  </section>
</template>
