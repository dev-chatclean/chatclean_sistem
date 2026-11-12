<script setup>
import { ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { useAdmin } from 'dashboard/composables/useAdmin';
import { useMapGetter } from 'dashboard/composables/store';
import { parseAPIErrorResponse } from 'dashboard/store/utils/api';
import { formatBytes } from 'shared/helpers/FileHelper';
import CrmDealFilesAPI from 'dashboard/api/crm/dealFiles';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import { DEAL_FILE_ACCEPT, DEAL_FILE_CATEGORIES } from '../../../constants';
import { formatDateTime } from './dealTime';

const props = defineProps({
  deal: { type: Object, required: true },
});

const emit = defineEmits(['changed']);

const { t, locale } = useI18n();
const { isAdmin } = useAdmin();
const currentUser = useMapGetter('getCurrentUser');

const category = ref(DEAL_FILE_CATEGORIES[0]);
const fileInput = ref(null);
const isUploading = ref(false);
const deleteDialogRef = ref(null);
const fileToDelete = ref(null);

const categoryLabel = value =>
  t(`CRM_DEALS.FILES.CATEGORIES.${value.toUpperCase()}`);

const canDelete = file =>
  isAdmin.value ||
  [file.uploaded_by_id, props.deal.assignee.id].includes(currentUser.value.id);

const fileIcon = file => {
  if (file.content_type.startsWith('image/')) return 'i-lucide-file-image';
  if (file.content_type === 'application/pdf') return 'i-lucide-file-text';
  if (file.content_type.includes('sheet') || file.content_type === 'text/csv')
    return 'i-lucide-file-spreadsheet';
  if (file.content_type === 'application/zip') return 'i-lucide-file-archive';
  return 'i-lucide-file';
};

const showError = error => {
  const message = parseAPIErrorResponse(error);
  useAlert(
    typeof message === 'string' ? message : t('CRM_PIPELINES.API.SAVE_ERROR')
  );
};

const upload = async event => {
  const [file] = event.target.files;
  event.target.value = '';
  if (!file) return;
  isUploading.value = true;
  try {
    await CrmDealFilesAPI.upload(props.deal.id, file, category.value);
    useAlert(t('CRM_DEALS.FILES.UPLOADED'));
    emit('changed');
  } catch (error) {
    showError(error);
  } finally {
    isUploading.value = false;
  }
};

const askDelete = file => {
  fileToDelete.value = file;
  deleteDialogRef.value?.open();
};

const confirmDelete = async () => {
  try {
    await CrmDealFilesAPI.remove(props.deal.id, fileToDelete.value.id);
    useAlert(t('CRM_DEALS.FILES.DELETED'));
    deleteDialogRef.value?.close();
    emit('changed');
  } catch (error) {
    deleteDialogRef.value?.close();
    showError(error);
  }
};
</script>

<template>
  <div class="flex flex-col gap-5">
    <div class="flex flex-wrap items-center justify-end gap-2">
      <select
        v-model="category"
        class="reset-base !w-56 h-10 px-3 text-sm rounded-xl border border-n-slate-6 bg-n-alpha-black2 text-n-slate-12"
        :aria-label="t('CRM_DEALS.FILES.CATEGORY')"
      >
        <option
          v-for="value in DEAL_FILE_CATEGORIES"
          :key="value"
          :value="value"
        >
          {{ categoryLabel(value) }}
        </option>
      </select>
      <button
        type="button"
        class="flex items-center gap-2 h-10 px-4 text-sm font-medium rounded-xl outline outline-1 -outline-offset-1 outline-n-slate-6 text-n-slate-12 hover:bg-n-alpha-1 disabled:opacity-60"
        :disabled="isUploading"
        @click="fileInput.click()"
      >
        <span
          class="size-4"
          :class="
            isUploading
              ? 'i-lucide-loader-circle animate-spin'
              : 'i-lucide-upload'
          "
        />
        {{ t('CRM_DEALS.FILES.UPLOAD') }}
      </button>
      <input
        ref="fileInput"
        type="file"
        class="hidden"
        :accept="DEAL_FILE_ACCEPT"
        @change="upload"
      />
    </div>

    <p
      v-if="!deal.files.length"
      class="py-10 text-base text-center text-n-slate-11"
    >
      {{ t('CRM_DEALS.FILES.EMPTY') }}
    </p>
    <ul v-else class="flex flex-col gap-2 p-0 m-0 list-none">
      <li
        v-for="file in deal.files"
        :key="file.id"
        class="flex items-center gap-3 p-3 rounded-xl outline outline-1 -outline-offset-1 outline-n-weak bg-n-solid-2"
      >
        <span
          class="flex items-center justify-center rounded-lg size-10 shrink-0 bg-n-alpha-2 text-n-slate-11"
        >
          <span class="size-5" :class="fileIcon(file)" />
        </span>
        <div class="flex flex-col flex-1 min-w-0 gap-1">
          <a
            :href="file.url"
            target="_blank"
            rel="noopener noreferrer"
            class="text-sm font-medium truncate text-n-slate-12 hover:underline"
          >
            {{ file.name }}
          </a>
          <span
            class="flex flex-wrap items-center gap-x-2 gap-y-1 text-label-small text-n-slate-11"
          >
            <span class="px-1.5 py-0.5 rounded-md bg-n-blue-3 text-n-blue-11">
              {{ categoryLabel(file.category) }}
            </span>
            <span>{{ formatBytes(file.size, 1) }}</span>
            <span>·</span>
            <span>{{ file.uploaded_by_name }}</span>
            <span>·</span>
            <span>{{ formatDateTime(file.created_at, locale) }}</span>
          </span>
        </div>
        <a
          :href="file.url"
          target="_blank"
          rel="noopener noreferrer"
          class="flex items-center justify-center rounded-lg size-8 text-n-slate-11 hover:bg-n-alpha-2 hover:text-n-slate-12"
          :aria-label="t('CRM_DEALS.FILES.DOWNLOAD')"
        >
          <span class="i-lucide-download size-4" />
        </a>
        <button
          v-if="canDelete(file)"
          type="button"
          class="flex items-center justify-center rounded-lg size-8 text-n-slate-11 hover:bg-n-alpha-2 hover:text-n-ruby-11"
          :aria-label="t('CRM_DEALS.FILES.DELETE')"
          @click="askDelete(file)"
        >
          <span class="i-lucide-trash-2 size-4" />
        </button>
      </li>
    </ul>

    <Dialog
      ref="deleteDialogRef"
      type="alert"
      :title="t('CRM_DEALS.FILES.DELETE')"
      :description="
        t('CRM_DEALS.FILES.DELETE_CONFIRM', { name: fileToDelete?.name || '' })
      "
      :confirm-button-label="t('CRM_DEALS.FILES.DELETE')"
      :cancel-button-label="t('CRM_DEALS.ACTIVITY.CANCEL')"
      @confirm="confirmDelete"
    />
  </div>
</template>
