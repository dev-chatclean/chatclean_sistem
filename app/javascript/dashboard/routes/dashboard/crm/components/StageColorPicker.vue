<script setup>
import { STAGE_COLORS } from '../constants';

const color = defineModel({ type: String, required: true });
</script>

<template>
  <div class="flex flex-wrap items-center gap-2">
    <button
      v-for="option in STAGE_COLORS"
      :key="option"
      type="button"
      class="rounded-full size-6 outline-offset-2 transition-transform hover:scale-110"
      :class="color === option ? 'outline outline-2 outline-n-slate-12' : ''"
      :style="{ backgroundColor: option }"
      :aria-label="option"
      :aria-pressed="color === option"
      @click="color = option"
    />
  </div>
</template>
