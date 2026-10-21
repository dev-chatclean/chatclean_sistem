<script setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { onClickOutside } from '@vueuse/core';
import Avatar from 'dashboard/components-next/avatar/Avatar.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import DropdownMenu from 'dashboard/components-next/dropdown-menu/DropdownMenu.vue';

const props = defineProps({
  deal: { type: Object, required: true },
  agents: { type: Array, default: () => [] },
});

const emit = defineEmits(['assign']);

const { t } = useI18n();
const currency = new Intl.NumberFormat('pt-BR', {
  style: 'currency',
  currency: 'BRL',
});

const showAssignMenu = ref(false);
const assignMenuRef = ref(null);
onClickOutside(assignMenuRef, () => {
  showAssignMenu.value = false;
});

const formattedValue = computed(() =>
  currency.format(Number(props.deal.value))
);
const isBlocked = computed(() => Boolean(props.deal.contact?.blocked));
const assigneeName = computed(
  () => props.deal.assignee?.name || t('CRM.KANBAN.CARD.UNASSIGNED')
);

// A rota da conversa usa o número de exibição (display_id), não o id.
const conversationRoute = computed(() => ({
  name: 'inbox_conversation',
  params: { conversation_id: props.deal.conversationDisplayId },
}));

const assignMenuItems = computed(() => {
  const items = props.agents.map(agent => ({
    label: agent.name,
    value: agent.id,
    action: 'assign',
    thumbnail: { name: agent.name, src: agent.thumbnail },
    isSelected: agent.id === props.deal.assigneeId,
  }));
  if (props.deal.assigneeId) {
    items.push({
      label: t('CRM.KANBAN.CARD.REMOVE_ASSIGNEE'),
      value: null,
      action: 'unassign',
      icon: 'i-lucide-user-x',
    });
  }
  return items;
});

const onAssign = ({ value }) => {
  showAssignMenu.value = false;
  if (value !== props.deal.assigneeId) emit('assign', value);
};
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
      <div ref="assignMenuRef" class="relative min-w-0">
        <button
          type="button"
          class="flex items-center min-w-0 gap-1.5 px-1 -mx-1 rounded-md hover:bg-n-alpha-2"
          :title="t('CRM.KANBAN.CARD.ASSIGN')"
          data-test="assignee"
          @click.stop="showAssignMenu = !showAssignMenu"
        >
          <Avatar
            v-if="deal.assignee"
            :src="deal.assignee.avatarUrl"
            :name="deal.assignee.name"
            :size="20"
            rounded-full
          />
          <Icon
            v-else
            icon="i-lucide-user-round"
            class="size-4 text-n-slate-10"
          />
          <span class="text-xs truncate text-n-slate-11">{{
            assigneeName
          }}</span>
        </button>
        <DropdownMenu
          v-if="showAssignMenu"
          :menu-items="assignMenuItems"
          :thumbnail-size="20"
          show-search
          class="mt-1 ltr:left-0 rtl:right-0 top-full z-60 max-h-64 overflow-y-auto"
          @action="onAssign"
        />
      </div>
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
