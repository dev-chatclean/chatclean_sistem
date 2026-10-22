<script setup>
import { computed, onMounted, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { useCrmSettingsStore } from 'dashboard/stores/crmSettings';
import Button from 'dashboard/components-next/button/Button.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import Switch from 'dashboard/components-next/switch/Switch.vue';
import {
  BaseTable,
  BaseTableRow,
  BaseTableCell,
} from 'dashboard/components-next/table';
import LossReasonDialog from './LossReasonDialog.vue';

const { t } = useI18n();
const crm = useCrmSettingsStore();

const dialogRef = ref(null);
const dialogError = ref('');
const isSaving = ref(false);

const headers = computed(() => [
  t('CRM.SETTINGS.LOSS_REASONS.TABLE.NAME'),
  t('CRM.SETTINGS.LOSS_REASONS.TABLE.DESCRIPTION'),
  t('CRM.SETTINGS.LOSS_REASONS.TABLE.ACTIVE'),
  t('CRM.SETTINGS.LOSS_REASONS.TABLE.ACTIONS'),
]);

const openCreate = () => {
  dialogError.value = '';
  dialogRef.value?.open();
};

const openEdit = reason => {
  dialogError.value = '';
  dialogRef.value?.open(reason);
};

// Erro de validação fica no modal, que continua aberto com os dados (FA 9.3).
const onSubmit = async ({ id, attributes }) => {
  dialogError.value = '';
  isSaving.value = true;
  try {
    if (id) {
      await crm.updateLossReason(id, attributes);
    } else {
      await crm.createLossReason(attributes);
    }
    dialogRef.value?.close();
    useAlert(t('CRM.SETTINGS.LOSS_REASONS.SAVED'));
  } catch (error) {
    dialogError.value = error.message;
  } finally {
    isSaving.value = false;
  }
};

const onToggleActive = (reason, isActive) =>
  crm
    .updateLossReason(reason.id, { is_active: isActive })
    .catch(error => useAlert(error.message));

onMounted(() => crm.fetchLossReasons().catch(error => useAlert(error.message)));

defineExpose({ openCreate });
</script>

<template>
  <div>
    <div
      v-if="crm.uiFlags.isFetchingLossReasons && !crm.lossReasons.length"
      class="flex justify-center py-10"
    >
      <Spinner />
    </div>
    <BaseTable
      v-else
      :headers="headers"
      :items="crm.lossReasons"
      :no-data-message="t('CRM.SETTINGS.LOSS_REASONS.EMPTY')"
    >
      <template #row="{ items }">
        <BaseTableRow v-for="reason in items" :key="reason.id" :item="reason">
          <template #default>
            <BaseTableCell class="whitespace-nowrap">
              <span class="text-body-main text-n-slate-12">
                {{ reason.name }}
              </span>
              <span
                v-if="reason.isSystem"
                class="px-2 py-0.5 ms-2 text-xs font-medium rounded bg-n-slate-3 text-n-slate-11"
                data-test="system-tag"
              >
                {{ t('CRM.SETTINGS.LOSS_REASONS.SYSTEM_TAG') }}
              </span>
            </BaseTableCell>
            <BaseTableCell class="w-full">
              <span class="text-body-main text-n-slate-11">
                {{ reason.description }}
              </span>
            </BaseTableCell>
            <BaseTableCell>
              <!-- O motivo de sistema não pode ser desativado (CA 9.5). -->
              <Switch
                :model-value="reason.isActive"
                :disabled="reason.isSystem"
                :title="
                  reason.isSystem
                    ? t('CRM.SETTINGS.LOSS_REASONS.SYSTEM_LOCKED')
                    : ''
                "
                data-test="active-switch"
                @update:model-value="value => onToggleActive(reason, value)"
              />
            </BaseTableCell>
            <BaseTableCell>
              <Button
                icon="i-lucide-pencil"
                size="xs"
                variant="ghost"
                color="slate"
                :title="t('CRM.SETTINGS.LOSS_REASONS.EDIT')"
                data-test="edit-reason"
                @click="openEdit(reason)"
              />
            </BaseTableCell>
          </template>
        </BaseTableRow>
      </template>
    </BaseTable>

    <LossReasonDialog
      ref="dialogRef"
      :is-loading="isSaving"
      :error-message="dialogError"
      @submit="onSubmit"
    />
  </div>
</template>
