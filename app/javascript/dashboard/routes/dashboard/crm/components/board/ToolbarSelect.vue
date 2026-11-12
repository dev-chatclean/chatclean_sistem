<script setup>
import { computed, ref } from 'vue';
import { vOnClickOutside } from '@vueuse/components';

const props = defineProps({
  label: { type: String, default: '' },
  icon: { type: String, default: '' },
  sections: { type: Array, required: true },
  selectedText: { type: String, default: '' },
});

const emit = defineEmits(['select']);

const isOpen = ref(false);

const buttonText = computed(() => props.selectedText);

const choose = (section, item) => {
  emit('select', { section: section.key, value: item.value });
  if (!item.keepOpen) isOpen.value = false;
};
</script>

<template>
  <div v-on-click-outside="() => (isOpen = false)" class="relative">
    <button
      type="button"
      class="flex items-center gap-1.5 h-9 px-3 text-sm rounded-xl outline outline-1 -outline-offset-1 outline-n-slate-6 bg-n-solid-2 text-n-slate-11 hover:text-n-slate-12"
      :aria-expanded="isOpen"
      @click="isOpen = !isOpen"
    >
      <span v-if="icon" class="size-3.5" :class="icon" />
      <span v-if="label">{{ label }}</span>
      <span v-if="buttonText" class="font-medium text-n-slate-12">
        {{ buttonText }}
      </span>
      <span
        class="i-lucide-chevron-down size-3.5 transition-transform"
        :class="{ 'rotate-180': isOpen }"
      />
    </button>
    <div
      v-if="isOpen"
      class="absolute z-50 flex flex-col gap-1 p-1.5 mt-1 min-w-52 rounded-xl border border-n-slate-6 bg-n-solid-2 shadow-lg top-full start-0"
    >
      <template v-for="(section, index) in sections" :key="section.key">
        <div
          v-if="index > 0"
          class="my-1 border-t border-n-slate-6"
          role="separator"
        />
        <span
          v-if="section.title"
          class="px-2.5 pt-1.5 pb-0.5 text-label-small text-n-slate-10"
        >
          {{ section.title }}
        </span>
        <button
          v-for="item in section.items"
          :key="String(item.value)"
          type="button"
          class="flex items-center gap-2 h-8 px-2.5 text-sm text-start rounded-lg"
          :class="
            item.selected
              ? 'bg-n-brand/10 text-n-slate-12'
              : 'text-n-slate-11 hover:bg-n-alpha-2 hover:text-n-slate-12'
          "
          @click="choose(section, item)"
        >
          <span
            class="i-lucide-check size-3.5 shrink-0"
            :class="item.selected ? 'text-n-brand' : 'invisible'"
          />
          {{ item.label }}
        </button>
        <slot :name="`section-${section.key}`" />
      </template>
    </div>
  </div>
</template>
