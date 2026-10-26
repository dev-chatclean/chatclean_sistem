<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useMapGetter } from 'dashboard/composables/store';
import { useAccount } from 'dashboard/composables/useAccount';
import SidebarProfileMenu from 'dashboard/components-next/sidebar/SidebarProfileMenu.vue';

// Barra superior da ChatClean atual (US 14, CCV2-29): atalho para os atendimentos, as
// notificações (antes "Caixa de entrada" no menu) e o perfil. Chat interno (US 26) e
// mensagens agendadas (US 25) entram aqui quando forem entregues.
const emit = defineEmits(['openKeyShortcutModal']);

const { t } = useI18n();
const { accountScopedRoute } = useAccount();
const unreadNotifications = useMapGetter('notifications/getUnreadCount');

const MAX_BADGE_COUNT = 99;
const notificationsBadge = computed(() =>
  unreadNotifications.value > MAX_BADGE_COUNT
    ? `${MAX_BADGE_COUNT}+`
    : unreadNotifications.value
);
</script>

<template>
  <header
    class="hidden md:flex items-center justify-end flex-shrink-0 gap-1 h-12 px-3 border-b border-n-weak bg-n-background"
    data-test="chatclean-top-bar"
  >
    <RouterLink
      :to="accountScopedRoute('home')"
      class="flex items-center gap-2 h-8 px-3 rounded-lg text-sm text-n-slate-11 hover:bg-n-alpha-2 hover:text-n-slate-12"
      active-class="!bg-n-alpha-2 !text-n-slate-12"
      data-test="top-bar-conversations"
    >
      <span class="i-lucide-message-circle size-4" />
      {{ t('CHATCLEAN.TOP_BAR.CONVERSATIONS') }}
    </RouterLink>
    <RouterLink
      :to="accountScopedRoute('inbox_view')"
      class="relative flex items-center justify-center size-8 rounded-lg text-n-slate-11 hover:bg-n-alpha-2 hover:text-n-slate-12"
      :title="t('CHATCLEAN.TOP_BAR.NOTIFICATIONS')"
      :aria-label="t('CHATCLEAN.TOP_BAR.NOTIFICATIONS')"
      data-test="top-bar-notifications"
    >
      <span class="i-lucide-bell size-4" />
      <span
        v-if="unreadNotifications"
        class="absolute -top-0.5 ltr:-right-0.5 rtl:-left-0.5 min-w-4 h-4 px-1 rounded-full bg-n-ruby-9 text-white text-xxs font-medium leading-4 text-center"
        data-test="top-bar-notifications-badge"
      >
        {{ notificationsBadge }}
      </span>
    </RouterLink>
    <SidebarProfileMenu
      is-collapsed
      dropdown-below
      @open-key-shortcut-modal="emit('openKeyShortcutModal')"
    />
  </header>
</template>
