<script setup>
import { useMapGetter } from 'dashboard/composables/store';

// Logo horizontal da ChatClean (CCV2-18): a versão clara no modo claro e a escura
// (LOGO_DARK) no modo escuro. Classes passadas pelo pai valem para as duas imagens.
defineOptions({ inheritAttrs: false });

const globalConfig = useMapGetter('globalConfig/get');
</script>

<template>
  <img
    v-bind="$attrs"
    :src="globalConfig.logo"
    :alt="globalConfig.installationName"
    :class="{ 'dark:hidden': globalConfig.logoDark }"
  />
  <img
    v-if="globalConfig.logoDark"
    v-bind="$attrs"
    :src="globalConfig.logoDark"
    :alt="globalConfig.installationName"
    class="hidden dark:block"
  />
</template>
