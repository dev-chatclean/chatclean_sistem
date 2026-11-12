<script setup>
// A plain table for the report blocks: the first column is text, the others are right-aligned numbers.
defineProps({
  columns: { type: Array, required: true },
  rows: { type: Array, required: true },
});
</script>

<template>
  <div class="overflow-x-auto border rounded-lg border-n-weak">
    <table class="w-full text-sm">
      <thead class="bg-n-alpha-1">
        <tr>
          <th
            v-for="(column, index) in columns"
            :key="column"
            class="px-3 py-2 font-normal text-label-small text-n-slate-11 whitespace-nowrap"
            :class="index === 0 ? 'text-start' : 'text-end'"
          >
            {{ column }}
          </th>
        </tr>
      </thead>
      <tbody>
        <tr v-for="row in rows" :key="row.key" class="border-t border-n-weak">
          <slot name="row" :row="row" />
        </tr>
      </tbody>
    </table>
  </div>
</template>
