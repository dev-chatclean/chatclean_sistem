<script setup>
defineProps({
  title: { type: String, required: true },
  description: { type: String, default: '' },
});
</script>

<template>
  <section
    class="flex flex-col min-w-0 gap-4 px-5 py-4 shadow outline-1 outline outline-n-container rounded-xl bg-n-solid-2"
  >
    <header class="flex items-start justify-between gap-3">
      <div class="flex flex-col min-w-0 gap-0.5">
        <h3 class="text-sm font-medium text-n-slate-12">{{ title }}</h3>
        <p v-if="description" class="text-sm text-n-slate-11">
          {{ description }}
        </p>
      </div>
      <slot name="actions" />
    </header>
    <slot />
  </section>
</template>
