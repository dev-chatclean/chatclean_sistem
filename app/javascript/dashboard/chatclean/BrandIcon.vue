<script setup>
import { useMapGetter } from 'dashboard/composables/store';

// Isotipo da ChatClean no menu recolhido: o verde (LOGO_THUMBNAIL) no modo claro e o
// dourado no modo escuro. Classes passadas pelo pai valem para as duas imagens.
defineOptions({ inheritAttrs: false });

const DARK_ISOTYPE_URL = '/brand-assets/chatclean/isotipo-dourado.png';

const globalConfig = useMapGetter('globalConfig/get');
</script>

<template>
  <img
    v-bind="$attrs"
    :src="globalConfig.logoThumbnail"
    :alt="globalConfig.installationName"
    class="dark:hidden"
  />
  <img
    v-bind="$attrs"
    :src="DARK_ISOTYPE_URL"
    :alt="globalConfig.installationName"
    class="hidden dark:block"
  />
</template>
