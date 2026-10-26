<script setup>
import { computed, ref, watchEffect } from 'vue';
import { useI18n } from 'vue-i18n';
import { useMapGetter } from 'dashboard/composables/store';
import { useAdmin } from 'dashboard/composables/useAdmin';
import Button from 'dashboard/components-next/button/Button.vue';
import Select from 'dashboard/components-next/select/Select.vue';
import TagMultiSelectComboBox from 'dashboard/components-next/combobox/TagMultiSelectComboBox.vue';
import { VISIBILITY, MAX_ATTACHMENTS_SIZE } from './cannedResponseForm';

// Campos da ChatClean no formulário de mensagem rápida (US 17): para quem fica disponível e os anexos.
// O atendente só cria "Só eu"; o administrador escolhe Todos, Departamentos ou Só eu.
const props = defineProps({
  existingAttachments: { type: Array, default: () => [] },
});

const visibility = defineModel('visibility', {
  type: String,
  default: VISIBILITY.PERSONAL,
});
const teamIds = defineModel('teamIds', { type: Array, default: () => [] });
const newFiles = defineModel('newFiles', { type: Array, default: () => [] });
const removeAttachmentIds = defineModel('removeAttachmentIds', {
  type: Array,
  default: () => [],
});
// Avisa o formulário quando os anexos passam de 16 MB, para ele não salvar (CA 17.4).
const overLimit = defineModel('overLimit', { type: Boolean, default: false });

const { t } = useI18n();
const { isAdmin } = useAdmin();
const teams = useMapGetter('teams/getTeams');
const fileInput = ref(null);

const visibilityOptions = computed(() =>
  Object.values(VISIBILITY).map(value => ({
    value,
    label: t(`CHATCLEAN.CANNED.VISIBILITY.${value.toUpperCase()}`),
  }))
);
const teamOptions = computed(() =>
  teams.value.map(team => ({ value: team.id, label: team.name }))
);
const keptAttachments = computed(() =>
  props.existingAttachments.filter(
    attachment => !removeAttachmentIds.value.includes(attachment.id)
  )
);
const totalSize = computed(
  () =>
    keptAttachments.value.reduce((sum, item) => sum + item.file_size, 0) +
    newFiles.value.reduce((sum, file) => sum + file.size, 0)
);
const isOverLimit = computed(() => totalSize.value > MAX_ATTACHMENTS_SIZE);
watchEffect(() => {
  overLimit.value = isOverLimit.value;
});

const addFiles = event => {
  newFiles.value = [...newFiles.value, ...event.target.files];
  event.target.value = '';
};
const removeNewFile = index => {
  newFiles.value = newFiles.value.filter((_, position) => position !== index);
};
const removeExisting = id => {
  removeAttachmentIds.value = [...removeAttachmentIds.value, id];
};
</script>

<template>
  <div class="flex flex-col gap-4">
    <label class="flex flex-col gap-1.5 text-sm text-n-slate-12">
      {{ t('CHATCLEAN.CANNED.VISIBILITY.LABEL') }}
      <Select
        v-if="isAdmin"
        v-model="visibility"
        :options="visibilityOptions"
        class="!w-full [&_select]:w-full"
        data-test="canned-visibility"
      />
      <span v-else class="text-n-slate-11" data-test="canned-personal-only">
        {{ t('CHATCLEAN.CANNED.VISIBILITY.PERSONAL') }}
      </span>
    </label>
    <label
      v-if="isAdmin && visibility === VISIBILITY.TEAMS"
      class="flex flex-col gap-1.5 text-sm text-n-slate-12"
    >
      {{ t('CHATCLEAN.CANNED.TEAMS') }}
      <TagMultiSelectComboBox
        v-model="teamIds"
        :options="teamOptions"
        :placeholder="t('CHATCLEAN.CANNED.TEAMS_PLACEHOLDER')"
        data-test="canned-teams"
      />
    </label>
    <div class="flex flex-col gap-2 text-sm text-n-slate-12">
      <div class="flex items-center justify-between">
        {{ t('CHATCLEAN.CANNED.ATTACHMENTS') }}
        <Button
          :label="t('CHATCLEAN.CANNED.ADD_ATTACHMENT')"
          icon="i-lucide-paperclip"
          size="xs"
          variant="faded"
          color="slate"
          type="button"
          @click="fileInput?.click()"
        />
        <input
          ref="fileInput"
          type="file"
          multiple
          class="hidden"
          data-test="canned-file-input"
          @change="addFiles"
        />
      </div>
      <ul class="flex flex-col gap-1">
        <li
          v-for="attachment in keptAttachments"
          :key="`saved-${attachment.id}`"
          class="flex items-center justify-between gap-2 px-3 py-1.5 rounded-lg bg-n-alpha-2"
        >
          <span class="truncate">{{ attachment.file_name }}</span>
          <Button
            icon="i-lucide-x"
            size="xs"
            variant="ghost"
            color="slate"
            type="button"
            @click="removeExisting(attachment.id)"
          />
        </li>
        <li
          v-for="(file, index) in newFiles"
          :key="`new-${index}-${file.name}`"
          class="flex items-center justify-between gap-2 px-3 py-1.5 rounded-lg bg-n-alpha-2"
        >
          <span class="truncate">{{ file.name }}</span>
          <Button
            icon="i-lucide-x"
            size="xs"
            variant="ghost"
            color="slate"
            type="button"
            @click="removeNewFile(index)"
          />
        </li>
      </ul>
      <p
        v-if="isOverLimit"
        class="text-n-ruby-11"
        data-test="canned-over-limit"
      >
        {{ t('CHATCLEAN.CANNED.OVER_LIMIT') }}
      </p>
    </div>
  </div>
</template>
