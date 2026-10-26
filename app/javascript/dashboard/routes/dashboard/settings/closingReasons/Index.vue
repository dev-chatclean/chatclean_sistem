<script setup>
import { computed, onMounted, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import BaseSettingsHeader from '../components/BaseSettingsHeader.vue';
import SettingsLayout from '../SettingsLayout.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import Switch from 'dashboard/components-next/switch/Switch.vue';
import {
  BaseTable,
  BaseTableRow,
  BaseTableCell,
} from 'dashboard/components-next/table';
import ClosingReasonsAPI from 'dashboard/api/chatclean/closingReasons';
import ClosingReasonFormDialog from './ClosingReasonFormDialog.vue';

// Cadastro dos motivos de fechamento (US 16, CCV2-24). Só o administrador acessa.
const { t } = useI18n();
const store = useStore();
const teams = useMapGetter('teams/getTeams');

const reasons = ref([]);
const isFetching = ref(true);
const formRef = ref(null);
const formError = ref('');
const isSaving = ref(false);
const deleteRef = ref(null);
const reasonToDelete = ref(null);

const headers = computed(() => [
  t('CHATCLEAN.CLOSING_REASONS.TABLE.NAME'),
  t('CHATCLEAN.CLOSING_REASONS.TABLE.TEAMS'),
  t('CHATCLEAN.CLOSING_REASONS.TABLE.SALE_VALUE'),
  t('CHATCLEAN.CLOSING_REASONS.TABLE.ACTIVE'),
  t('CHATCLEAN.CLOSING_REASONS.TABLE.ACTIONS'),
]);

const teamNames = reason =>
  reason.team_ids.length
    ? teams.value
        .filter(team => reason.team_ids.includes(team.id))
        .map(team => team.name)
        .join(', ')
    : t('CHATCLEAN.CLOSING_REASONS.ALL_TEAMS');

const apiError = error => error?.response?.data?.message || error.message;

const fetchReasons = async () => {
  try {
    const { data } = await ClosingReasonsAPI.get();
    reasons.value = data.payload;
  } catch (error) {
    useAlert(apiError(error));
  } finally {
    isFetching.value = false;
  }
};

const openForm = (reason = null) => {
  formError.value = '';
  formRef.value?.open(reason);
};

// Erro de validação fica no formulário, que continua aberto com os dados.
const onSubmit = async ({ id, attributes }) => {
  formError.value = '';
  isSaving.value = true;
  try {
    if (id) {
      await ClosingReasonsAPI.update(id, { closing_reason: attributes });
    } else {
      await ClosingReasonsAPI.create({ closing_reason: attributes });
    }
    formRef.value?.close();
    useAlert(t('CHATCLEAN.CLOSING_REASONS.SAVED'));
    await fetchReasons();
  } catch (error) {
    formError.value = apiError(error);
  } finally {
    isSaving.value = false;
  }
};

const onToggleActive = async (reason, isActive) => {
  try {
    await ClosingReasonsAPI.update(reason.id, {
      closing_reason: { is_active: isActive },
    });
    reason.is_active = isActive;
  } catch (error) {
    useAlert(apiError(error));
  }
};

const askDelete = reason => {
  reasonToDelete.value = reason;
  deleteRef.value?.open();
};

// Motivo já usado não é excluído (CA 16.2): o servidor recusa e a mensagem aparece.
const onDelete = async () => {
  try {
    await ClosingReasonsAPI.delete(reasonToDelete.value.id);
    useAlert(t('CHATCLEAN.CLOSING_REASONS.DELETED'));
    await fetchReasons();
  } catch (error) {
    useAlert(apiError(error));
  } finally {
    deleteRef.value?.close();
  }
};

onMounted(() => {
  store.dispatch('teams/get');
  fetchReasons();
});
</script>

<template>
  <SettingsLayout :is-loading="isFetching">
    <template #header>
      <BaseSettingsHeader
        :title="t('CHATCLEAN.CLOSING_REASONS.HEADER')"
        :description="t('CHATCLEAN.CLOSING_REASONS.DESCRIPTION')"
      >
        <template #actions>
          <Button
            :label="t('CHATCLEAN.CLOSING_REASONS.NEW')"
            icon="i-lucide-plus"
            size="sm"
            data-test="create"
            @click="openForm()"
          />
        </template>
      </BaseSettingsHeader>
    </template>
    <template #body>
      <BaseTable
        :headers="headers"
        :items="reasons"
        :no-data-message="t('CHATCLEAN.CLOSING_REASONS.EMPTY')"
      >
        <template #row="{ items }">
          <BaseTableRow v-for="reason in items" :key="reason.id" :item="reason">
            <template #default>
              <BaseTableCell class="whitespace-nowrap">
                <span class="text-body-main text-n-slate-12">
                  {{ reason.name }}
                </span>
              </BaseTableCell>
              <BaseTableCell class="w-full">
                <span class="text-body-main text-n-slate-11">
                  {{ teamNames(reason) }}
                </span>
              </BaseTableCell>
              <BaseTableCell class="whitespace-nowrap">
                <span
                  v-if="reason.ask_sale_value"
                  class="text-body-main text-n-slate-11"
                >
                  {{ t('CHATCLEAN.CLOSING_REASONS.ASKS_SALE_VALUE') }}
                </span>
              </BaseTableCell>
              <BaseTableCell>
                <Switch
                  :model-value="reason.is_active"
                  data-test="active-switch"
                  @update:model-value="value => onToggleActive(reason, value)"
                />
              </BaseTableCell>
              <BaseTableCell class="whitespace-nowrap">
                <Button
                  icon="i-lucide-pencil"
                  size="xs"
                  variant="ghost"
                  color="slate"
                  :title="t('CHATCLEAN.CLOSING_REASONS.EDIT')"
                  data-test="edit-reason"
                  @click="openForm(reason)"
                />
                <Button
                  icon="i-lucide-trash-2"
                  size="xs"
                  variant="ghost"
                  color="ruby"
                  :title="t('CHATCLEAN.CLOSING_REASONS.DELETE')"
                  data-test="delete-reason"
                  @click="askDelete(reason)"
                />
              </BaseTableCell>
            </template>
          </BaseTableRow>
        </template>
      </BaseTable>

      <ClosingReasonFormDialog
        ref="formRef"
        :is-loading="isSaving"
        :error-message="formError"
        @submit="onSubmit"
      />
      <Dialog
        ref="deleteRef"
        type="alert"
        :title="t('CHATCLEAN.CLOSING_REASONS.DELETE_CONFIRM.TITLE')"
        :description="
          t('CHATCLEAN.CLOSING_REASONS.DELETE_CONFIRM.DESCRIPTION', {
            name: reasonToDelete?.name,
          })
        "
        :confirm-button-label="
          t('CHATCLEAN.CLOSING_REASONS.DELETE_CONFIRM.CONFIRM')
        "
        @confirm="onDelete"
      />
    </template>
  </SettingsLayout>
</template>
