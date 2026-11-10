<script setup>
defineProps({
  options: { type: Array, required: true },
  disabled: { type: Boolean, default: false },
});

const selected = defineModel({ type: String, required: true });
</script>

<template>
  <div class="flex flex-wrap gap-2">
    <button
      v-for="option in options"
      :key="option.value"
      type="button"
      :disabled="disabled"
      class="flex items-center gap-1 px-3 py-1.5 text-sm outline outline-1 -outline-offset-1 rounded-full disabled:cursor-not-allowed disabled:opacity-60"
      :class="
        selected === option.value
          ? 'outline-n-brand bg-n-brand/10 text-n-blue-11'
          : 'outline-n-slate-6 text-n-slate-12 hover:bg-n-alpha-1'
      "
      @click="selected = option.value"
    >
      <span v-if="selected === option.value" class="i-lucide-check size-3.5" />
      {{ option.label }}
    </button>
  </div>
</template>
