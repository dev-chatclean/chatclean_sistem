<script setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { onClickOutside } from '@vueuse/core';
import Avatar from 'dashboard/components-next/avatar/Avatar.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import DropdownMenu from 'dashboard/components-next/dropdown-menu/DropdownMenu.vue';
import { useAdmin } from 'dashboard/composables/useAdmin';

// Responsável do deal com troca rápida, usado no Kanban e no painel da conversa.
// Só o administrador troca o responsável (US 27); para o atendente, só mostra.
const props = defineProps({
  deal: { type: Object, required: true },
  agents: { type: Array, default: () => [] },
  disabled: { type: Boolean, default: false },
});

const emit = defineEmits(['assign']);

const { t } = useI18n();
const { isAdmin } = useAdmin();

const showMenu = ref(false);
const pickerRef = ref(null);
onClickOutside(pickerRef, () => {
  showMenu.value = false;
});

const assigneeName = computed(
  () => props.deal.assignee?.name || t('CRM.KANBAN.CARD.UNASSIGNED')
);

const menuItems = computed(() => {
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

const onAction = ({ value }) => {
  showMenu.value = false;
  if (value !== props.deal.assigneeId) emit('assign', value);
};
</script>

<template>
  <div ref="pickerRef" class="relative min-w-0">
    <button
      type="button"
      class="flex items-center min-w-0 gap-1.5 px-1 -mx-1 rounded-md enabled:hover:bg-n-alpha-2 disabled:cursor-not-allowed"
      :title="t('CRM.KANBAN.CARD.ASSIGN')"
      :disabled="disabled || !isAdmin"
      data-test="assignee"
      @click.stop="showMenu = !showMenu"
    >
      <Avatar
        v-if="deal.assignee"
        :src="deal.assignee.avatarUrl"
        :name="deal.assignee.name"
        :size="20"
        rounded-full
      />
      <Icon v-else icon="i-lucide-user-round" class="size-4 text-n-slate-10" />
      <span class="text-xs truncate text-n-slate-11">{{ assigneeName }}</span>
    </button>
    <DropdownMenu
      v-if="showMenu"
      :menu-items="menuItems"
      :thumbnail-size="20"
      show-search
      class="mt-1 ltr:left-0 rtl:right-0 top-full z-60 max-h-64 overflow-y-auto"
      @action="onAction"
    />
  </div>
</template>
