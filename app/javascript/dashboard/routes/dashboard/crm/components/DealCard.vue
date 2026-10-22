<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { formatCurrency } from '../helpers/currency';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import AssigneePicker from './AssigneePicker.vue';

const props = defineProps({
  deal: { type: Object, required: true },
  agents: { type: Array, default: () => [] },
});

const emit = defineEmits(['assign']);

const { t } = useI18n();

const formattedValue = computed(() => formatCurrency(props.deal.value));
const isBlocked = computed(() => Boolean(props.deal.contact?.blocked));

// A rota da conversa usa o número de exibição (display_id), não o id.
const conversationRoute = computed(() => ({
  name: 'inbox_conversation',
  params: { conversation_id: props.deal.conversationDisplayId },
}));
</script>

<template>
  <article
    class="flex flex-col gap-2 p-3 rounded-lg outline outline-1 outline-n-container bg-n-solid-1"
    :class="isBlocked ? 'opacity-70 cursor-not-allowed' : 'cursor-grab'"
    :data-deal-id="deal.id"
  >
    <h4 class="text-sm font-medium text-n-slate-12 line-clamp-2 break-words">
      {{ deal.title }}
    </h4>
    <span class="text-sm font-semibold tabular-nums text-n-slate-12">
      {{ formattedValue }}
    </span>
    <div class="flex items-center gap-1.5 min-w-0 text-xs text-n-slate-11">
      <Icon icon="i-lucide-user-round" class="size-3.5 shrink-0" />
      <span class="truncate">{{ deal.contact?.name }}</span>
      <span
        v-if="isBlocked"
        class="inline-flex items-center gap-1 px-1.5 rounded-md shrink-0 bg-n-ruby-3 text-n-ruby-11"
      >
        <Icon icon="i-lucide-lock" class="size-3" />
        {{ t('CRM.KANBAN.CARD.BLOCKED_CONTACT') }}
      </span>
    </div>
    <footer
      class="flex items-center justify-between gap-2 pt-2 mt-1 border-t border-n-weak"
    >
      <AssigneePicker
        :deal="deal"
        :agents="agents"
        :disabled="isBlocked"
        @assign="assigneeId => emit('assign', assigneeId)"
      />
      <RouterLink
        v-if="deal.conversationDisplayId"
        :to="conversationRoute"
        :title="t('CRM.KANBAN.CARD.OPEN_CONVERSATION')"
        :aria-label="t('CRM.KANBAN.CARD.OPEN_CONVERSATION')"
        class="flex items-center justify-center p-1 rounded-md shrink-0 text-n-slate-11 hover:text-n-blue-11 hover:bg-n-alpha-2"
        data-test="open-conversation"
        @click.stop
      >
        <Icon icon="i-lucide-message-circle" class="size-4" />
      </RouterLink>
    </footer>
  </article>
</template>
