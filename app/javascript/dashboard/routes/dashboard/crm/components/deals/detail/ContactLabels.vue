<script setup>
import { computed, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { vOnClickOutside } from '@vueuse/components';
import ContactAPI from 'dashboard/api/contacts';
import { useAlert } from 'dashboard/composables';
import { useMapGetter } from 'dashboard/composables/store';

const props = defineProps({
  contactId: { type: Number, default: null },
});

const { t } = useI18n();
const accountLabels = useMapGetter('labels/getLabels');

const labels = ref([]);
const isOpen = ref(false);

const colorOf = title =>
  accountLabels.value.find(label => label.title === title)?.color;

const load = async () => {
  labels.value = [];
  if (!props.contactId) return;
  try {
    const { data } = await ContactAPI.getContactLabels(props.contactId);
    labels.value = data.payload;
  } catch (error) {
    labels.value = [];
  }
};

watch(() => props.contactId, load, { immediate: true });

const available = computed(() => accountLabels.value.map(label => label.title));

const toggle = async title => {
  const next = labels.value.includes(title)
    ? labels.value.filter(item => item !== title)
    : [...labels.value, title];
  try {
    const { data } = await ContactAPI.updateContactLabels(
      props.contactId,
      next
    );
    labels.value = data.payload;
  } catch (error) {
    useAlert(t('CRM_PIPELINES.API.SAVE_ERROR'));
  }
};
</script>

<template>
  <div class="flex flex-wrap items-center gap-2">
    <span v-if="!labels.length" class="text-sm text-n-slate-11">
      {{ t('CRM_DEALS.DETAIL.NO_LABELS') }}
    </span>
    <span
      v-for="label in labels"
      :key="label"
      class="flex items-center gap-1.5 px-2 py-0.5 text-label-small rounded-md border border-n-slate-6 text-n-slate-12"
    >
      <span
        class="rounded-full size-2"
        :style="{ backgroundColor: colorOf(label) }"
      />
      {{ label }}
    </span>
    <div v-on-click-outside="() => (isOpen = false)" class="relative">
      <button
        type="button"
        class="flex items-center justify-center rounded-md size-7 outline outline-1 -outline-offset-1 outline-n-slate-6 text-n-slate-11 hover:text-n-slate-12 disabled:opacity-50 disabled:cursor-not-allowed"
        :disabled="!props.contactId"
        :title="
          props.contactId
            ? t('CRM_DEALS.DETAIL.ADD_LABEL')
            : t('CRM_DEALS.DETAIL.LABELS_NEED_CONTACT')
        "
        @click="isOpen = !isOpen"
      >
        <span class="i-lucide-plus size-4" />
      </button>
      <div
        v-if="isOpen"
        class="absolute z-50 flex flex-col gap-1 p-1.5 mt-1 w-56 max-h-64 overflow-y-auto rounded-xl border border-n-slate-6 bg-n-solid-2 shadow-lg top-full start-0"
      >
        <span
          v-if="!available.length"
          class="px-2 py-1.5 text-sm text-n-slate-11"
        >
          {{ t('CRM_PIPELINES.STAGE.REQUIREMENTS.LABELS.EMPTY') }}
        </span>
        <button
          v-for="title in available"
          :key="title"
          type="button"
          class="flex items-center gap-2 h-8 px-2.5 text-sm text-start rounded-lg text-n-slate-12 hover:bg-n-alpha-2"
          @click="toggle(title)"
        >
          <span
            class="i-lucide-check size-3.5"
            :class="labels.includes(title) ? 'text-n-brand' : 'invisible'"
          />
          <span
            class="rounded-full size-2"
            :style="{ backgroundColor: colorOf(title) }"
          />
          {{ title }}
        </button>
      </div>
    </div>
  </div>
</template>
