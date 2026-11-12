<script setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import Draggable from 'vuedraggable';
import { vOnClickOutside } from '@vueuse/components';
import Checkbox from 'dashboard/components-next/checkbox/Checkbox.vue';

// "Blocos": show, hide and reorder the blocks of the report.
const props = defineProps({
  blocks: { type: Array, required: true },
});

const emit = defineEmits(['reorder', 'toggle', 'showAll']);

const { t } = useI18n();
const isOpen = ref(false);

const hiddenCount = computed(
  () => props.blocks.filter(block => !block.visible).length
);

const items = computed({
  get: () => props.blocks,
  set: value =>
    emit(
      'reorder',
      value.map(block => block.key)
    ),
});
</script>

<template>
  <div v-on-click-outside="() => (isOpen = false)" class="relative">
    <button
      type="button"
      class="flex items-center gap-1.5 h-9 px-3 text-sm border rounded-xl border-n-slate-6 bg-n-solid-2 text-n-slate-11 hover:text-n-slate-12"
      @click="isOpen = !isOpen"
    >
      <span class="i-lucide-layout-grid size-3.5" />
      {{ t('CRM_REPORTS.SALES.BLOCKS.BUTTON') }}
    </button>
    <div
      v-if="isOpen"
      class="absolute z-50 flex flex-col gap-1 p-1.5 mt-1 w-80 rounded-xl border border-n-slate-6 bg-n-solid-2 shadow-lg top-full start-0"
    >
      <div class="flex items-center justify-between px-2 py-1 text-label-small">
        <span class="text-n-slate-11">
          {{
            hiddenCount
              ? t(
                  'CRM_REPORTS.SALES.BLOCKS.HIDDEN_COUNT',
                  { count: hiddenCount },
                  hiddenCount
                )
              : t('CRM_REPORTS.SALES.BLOCKS.ALL_VISIBLE')
          }}
        </span>
        <button
          type="button"
          class="text-n-brand hover:underline"
          @click="emit('showAll')"
        >
          {{ t('CRM_REPORTS.SALES.BLOCKS.SHOW_ALL') }}
        </button>
      </div>
      <Draggable
        v-model="items"
        item-key="key"
        handle=".drag-handle"
        class="flex flex-col overflow-y-auto max-h-96"
      >
        <template #item="{ element }">
          <div
            class="flex items-center gap-2 px-2 text-sm rounded-lg h-8 text-n-slate-12 hover:bg-n-alpha-2"
          >
            <span
              v-tooltip.left="t('CRM_REPORTS.SALES.BLOCKS.DRAG')"
              class="drag-handle i-lucide-grip-vertical size-4 cursor-grab text-n-slate-10 shrink-0"
            />
            <Checkbox
              :model-value="element.visible"
              @update:model-value="emit('toggle', element.key)"
            />
            <span class="truncate">{{ element.label }}</span>
          </div>
        </template>
      </Draggable>
    </div>
  </div>
</template>
