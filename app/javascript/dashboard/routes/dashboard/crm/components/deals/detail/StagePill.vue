<script setup>
import { computed, ref } from 'vue';
import { vOnClickOutside } from '@vueuse/components';

const props = defineProps({
  stages: { type: Array, default: () => [] },
  stageId: { type: Number, default: null },
});

const emit = defineEmits(['select']);

const isOpen = ref(false);

const current = computed(() =>
  props.stages.find(stage => stage.id === props.stageId)
);

const choose = stage => {
  isOpen.value = false;
  if (stage.id !== props.stageId) emit('select', stage);
};
</script>

<template>
  <div v-on-click-outside="() => (isOpen = false)" class="relative">
    <button
      type="button"
      class="flex items-center gap-2.5 h-11 ps-4 pe-3 min-w-44 text-base font-medium rounded-xl outline outline-1 -outline-offset-1 outline-n-slate-6 text-n-slate-12 hover:bg-n-alpha-1"
      @click="isOpen = !isOpen"
    >
      <span
        class="rounded-full size-2.5 shrink-0"
        :style="{ backgroundColor: current?.color }"
      />
      <span class="flex-1 text-start truncate">{{ current?.name }}</span>
      <span class="i-lucide-chevrons-up-down size-4 text-n-slate-11" />
    </button>
    <div
      v-if="isOpen"
      class="absolute z-50 flex flex-col gap-1 p-1.5 mt-1 w-full min-w-52 rounded-xl border border-n-slate-6 bg-n-solid-2 shadow-lg top-full end-0"
    >
      <button
        v-for="stage in props.stages"
        :key="stage.id"
        type="button"
        class="flex items-center gap-2.5 h-9 px-3 text-sm text-start rounded-lg"
        :class="
          stage.id === props.stageId
            ? 'bg-n-alpha-2 text-n-slate-12'
            : 'text-n-slate-12 hover:bg-n-alpha-2'
        "
        @click="choose(stage)"
      >
        <span
          class="rounded-full size-2.5 shrink-0"
          :style="{ backgroundColor: stage.color }"
        />
        {{ stage.name }}
      </button>
    </div>
  </div>
</template>
