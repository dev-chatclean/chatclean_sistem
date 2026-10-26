<script setup>
import { computed, onMounted, reactive, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import Button from 'dashboard/components-next/button/Button.vue';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import Select from 'dashboard/components-next/select/Select.vue';
import TextArea from 'dashboard/components-next/textarea/TextArea.vue';
import {
  BaseTable,
  BaseTableRow,
  BaseTableCell,
} from 'dashboard/components-next/table';
import HolidaysAPI from 'dashboard/api/chatclean/holidays';

// Feriados da conta (US 19): um por data, listados por ano, com importação dos nacionais.
const { t } = useI18n();
const currentYear = new Date().getFullYear();
const year = ref(currentYear);
const holidays = ref([]);
const isImporting = ref(false);
const isSaving = ref(false);
const formRef = ref(null);
const deleteRef = ref(null);
const editing = ref(null);
const toDelete = ref(null);
const formError = ref('');
const form = reactive({ date: '', name: '', message: '' });

const yearOptions = [
  currentYear - 1,
  currentYear,
  currentYear + 1,
  currentYear + 2,
].map(value => ({ value, label: String(value) }));
const headers = computed(() => [
  t('CHATCLEAN.HOLIDAYS.TABLE.DATE'),
  t('CHATCLEAN.HOLIDAYS.TABLE.NAME'),
  t('CHATCLEAN.HOLIDAYS.TABLE.MESSAGE'),
  t('CHATCLEAN.HOLIDAYS.TABLE.ACTIONS'),
]);
const canSave = computed(() => Boolean(form.date && form.name.trim()));

const formatDate = date =>
  new Date(`${date}T12:00:00`).toLocaleDateString(undefined, {
    day: '2-digit',
    month: '2-digit',
  });
const apiError = error =>
  error?.response?.data?.message || t('CHATCLEAN.HOLIDAYS.ERROR');

const fetchHolidays = async () => {
  const { data } = await HolidaysAPI.getByYear(year.value);
  holidays.value = data;
};

const importNational = async () => {
  isImporting.value = true;
  try {
    const { data } = await HolidaysAPI.importNational(year.value);
    holidays.value = data;
    useAlert(t('CHATCLEAN.HOLIDAYS.IMPORTED'));
  } catch (error) {
    useAlert(apiError(error));
  } finally {
    isImporting.value = false;
  }
};

const openForm = (holiday = null) => {
  editing.value = holiday;
  formError.value = '';
  Object.assign(form, {
    date: holiday?.date || '',
    name: holiday?.name || '',
    message: holiday?.message || '',
  });
  formRef.value?.open();
};

const save = async () => {
  if (!canSave.value) return;
  isSaving.value = true;
  formError.value = '';
  const attributes = {
    date: form.date,
    name: form.name.trim(),
    message: form.message.trim() || null,
  };
  try {
    if (editing.value) {
      await HolidaysAPI.update(editing.value.id, { holiday: attributes });
    } else {
      await HolidaysAPI.create({ holiday: attributes });
    }
    formRef.value?.close();
    useAlert(t('CHATCLEAN.HOLIDAYS.SAVED'));
    await fetchHolidays();
  } catch (error) {
    formError.value = apiError(error);
  } finally {
    isSaving.value = false;
  }
};

const askDelete = holiday => {
  toDelete.value = holiday;
  deleteRef.value?.open();
};

const remove = async () => {
  try {
    await HolidaysAPI.delete(toDelete.value.id);
    await fetchHolidays();
  } catch (error) {
    useAlert(apiError(error));
  } finally {
    deleteRef.value?.close();
  }
};

watch(year, fetchHolidays);
onMounted(fetchHolidays);
</script>

<template>
  <div class="flex flex-col gap-4">
    <div class="flex items-center justify-between gap-3">
      <Select v-model="year" :options="yearOptions" data-test="holidays-year" />
      <div class="flex gap-2">
        <Button
          :label="t('CHATCLEAN.HOLIDAYS.IMPORT', { year })"
          icon="i-lucide-download"
          size="sm"
          variant="faded"
          color="slate"
          :is-loading="isImporting"
          data-test="holidays-import"
          @click="importNational"
        />
        <Button
          :label="t('CHATCLEAN.HOLIDAYS.NEW')"
          icon="i-lucide-plus"
          size="sm"
          data-test="holidays-new"
          @click="openForm()"
        />
      </div>
    </div>

    <BaseTable
      :headers="headers"
      :items="holidays"
      :no-data-message="t('CHATCLEAN.HOLIDAYS.EMPTY')"
    >
      <template #row="{ items }">
        <BaseTableRow
          v-for="holiday in items"
          :key="holiday.id"
          :item="holiday"
        >
          <template #default>
            <BaseTableCell class="whitespace-nowrap">
              <span class="text-body-main text-n-slate-12">
                {{ formatDate(holiday.date) }}
              </span>
            </BaseTableCell>
            <BaseTableCell class="whitespace-nowrap">
              <span class="text-body-main text-n-slate-12">
                {{ holiday.name }}
              </span>
            </BaseTableCell>
            <BaseTableCell class="w-full">
              <span class="text-body-main text-n-slate-11">
                {{ holiday.message || t('CHATCLEAN.HOLIDAYS.DEFAULT_MESSAGE') }}
              </span>
            </BaseTableCell>
            <BaseTableCell class="whitespace-nowrap">
              <Button
                icon="i-lucide-pencil"
                size="xs"
                variant="ghost"
                color="slate"
                :title="t('CHATCLEAN.HOLIDAYS.EDIT')"
                @click="openForm(holiday)"
              />
              <Button
                icon="i-lucide-trash-2"
                size="xs"
                variant="ghost"
                color="ruby"
                :title="t('CHATCLEAN.HOLIDAYS.DELETE')"
                @click="askDelete(holiday)"
              />
            </BaseTableCell>
          </template>
        </BaseTableRow>
      </template>
    </BaseTable>

    <Dialog
      ref="formRef"
      :title="
        editing ? t('CHATCLEAN.HOLIDAYS.EDIT') : t('CHATCLEAN.HOLIDAYS.NEW')
      "
      :confirm-button-label="t('CHATCLEAN.HOLIDAYS.SAVE')"
      :disable-confirm-button="!canSave"
      :is-loading="isSaving"
      @confirm="save"
    >
      <div class="flex flex-col gap-4">
        <Input
          v-model="form.date"
          type="date"
          :label="t('CHATCLEAN.HOLIDAYS.FORM.DATE')"
          data-test="holiday-date"
        />
        <Input
          v-model="form.name"
          :label="t('CHATCLEAN.HOLIDAYS.FORM.NAME')"
          :message="formError"
          :message-type="formError ? 'error' : 'info'"
          data-test="holiday-name"
        />
        <TextArea
          v-model="form.message"
          :label="t('CHATCLEAN.HOLIDAYS.FORM.MESSAGE')"
          :placeholder="t('CHATCLEAN.HOLIDAYS.DEFAULT_MESSAGE')"
          data-test="holiday-message"
        />
      </div>
    </Dialog>
    <Dialog
      ref="deleteRef"
      type="alert"
      :title="t('CHATCLEAN.HOLIDAYS.DELETE')"
      :description="
        t('CHATCLEAN.HOLIDAYS.DELETE_CONFIRM', { name: toDelete?.name })
      "
      :confirm-button-label="t('CHATCLEAN.HOLIDAYS.DELETE')"
      @confirm="remove"
    />
  </div>
</template>
