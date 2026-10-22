<script>
import FeaturePlaceholder from './FeaturePlaceholder.vue';
import BrandLogo from 'dashboard/chatclean/BrandLogo.vue';

export default {
  components: { FeaturePlaceholder, BrandLogo },
  props: {
    message: {
      type: String,
      required: true,
    },
  },
};
</script>

<template>
  <div class="flex flex-col items-center justify-center h-full">
    <!-- ChatClean: logo oficial no lugar da ilustração do Chatwoot (CCV2-18). -->
    <BrandLogo class="w-auto h-12 m-6" />
    <span class="text-sm text-n-slate-12 font-medium text-center">
      {{ message }}
      <br />
    </span>
    <!-- Cmd bar, keyboard shortcuts placeholder -->
    <FeaturePlaceholder />
  </div>
</template>
