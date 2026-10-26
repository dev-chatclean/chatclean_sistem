<script setup>
import ChannelIcon from 'dashboard/components-next/icon/ChannelIcon.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';

// Etiquetas do card na ChatClean (US 15): número do atendimento, canal, atendente e departamento,
// cada um com uma cor para bater o olho.
defineProps({
  displayId: { type: Number, required: true },
  inbox: { type: Object, default: () => ({}) },
  assignee: { type: Object, default: () => ({}) },
  assigneeIsBot: { type: Boolean, default: false },
  team: { type: Object, default: null },
});
</script>

<template>
  <div
    class="flex items-center gap-1 min-w-0 overflow-hidden"
    data-test="card-tags"
  >
    <span class="text-label-small text-n-slate-10 shrink-0">
      {{ `#${displayId}` }}
    </span>
    <span
      v-if="inbox.name"
      class="inline-flex items-center gap-0.5 h-5 px-1.5 rounded-md bg-n-teal-3 text-n-teal-11 text-label-small min-w-0"
      :title="inbox.name"
      data-test="card-tag-channel"
    >
      <ChannelIcon :inbox="inbox" class="size-3 shrink-0" />
      <span class="truncate">{{ inbox.name }}</span>
    </span>
    <span
      v-if="assignee.name"
      class="inline-flex items-center gap-0.5 h-5 px-1.5 rounded-md bg-n-blue-3 text-n-blue-11 text-label-small min-w-0"
      :title="assignee.name"
      data-test="card-tag-agent"
    >
      <Icon
        :icon="assigneeIsBot ? 'i-lucide-bot' : 'i-lucide-user-round'"
        class="size-3 shrink-0"
      />
      <span class="truncate">{{ assignee.name }}</span>
    </span>
    <span
      v-if="team"
      class="inline-flex items-center gap-0.5 h-5 px-1.5 rounded-md bg-n-iris-3 text-n-iris-11 text-label-small min-w-0"
      :title="team.name"
      data-test="card-tag-team"
    >
      <Icon icon="i-lucide-users" class="size-3 shrink-0" />
      <span class="truncate">{{ team.name }}</span>
    </span>
  </div>
</template>
