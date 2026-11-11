<script setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { parseAPIErrorResponse } from 'dashboard/store/utils/api';
import CrmProductsAPI from 'dashboard/api/crm/products';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import {
  PRODUCT_NAME_MAX_LENGTH,
  PRODUCT_SKU_MAX_LENGTH,
} from '../../constants';

const emit = defineEmits(['saved']);

const { t } = useI18n();

const dialogRef = ref(null);
const product = ref(null);
const form = ref({});
const isSaving = ref(false);

const isInvalid = computed(() => {
  const name = form.value.name?.trim() || '';
  return (
    !name ||
    name.length > PRODUCT_NAME_MAX_LENGTH ||
    (form.value.sku?.length || 0) > PRODUCT_SKU_MAX_LENGTH ||
    form.value.price === '' ||
    Number(form.value.price) < 0
  );
});

const open = (target = null) => {
  product.value = target;
  form.value = {
    name: target?.name || '',
    description: target?.description || '',
    price: target ? String(target.price) : '',
    sku: target?.sku || '',
    active: target ? target.active : true,
  };
  dialogRef.value?.open();
};

const save = async () => {
  if (isSaving.value || isInvalid.value) return;
  isSaving.value = true;
  const payload = {
    product: {
      name: form.value.name.trim(),
      description: form.value.description.trim() || null,
      price: Number(form.value.price),
      sku: form.value.sku.trim() || null,
      active: form.value.active,
    },
  };
  try {
    if (product.value) {
      await CrmProductsAPI.update(product.value.id, payload);
    } else {
      await CrmProductsAPI.create(payload);
    }
    useAlert(t('CRM_PRODUCTS.API.SAVE_SUCCESS'));
    dialogRef.value?.close();
    emit('saved');
  } catch (error) {
    const message = parseAPIErrorResponse(error);
    useAlert(
      typeof message === 'string' ? message : t('CRM_PRODUCTS.API.SAVE_ERROR')
    );
  } finally {
    isSaving.value = false;
  }
};

defineExpose({ open });
</script>

<template>
  <Dialog
    ref="dialogRef"
    :title="product ? t('CRM_PRODUCTS.FORM.EDIT') : t('CRM_PRODUCTS.FORM.NEW')"
    :confirm-button-label="t('CRM_PRODUCTS.FORM.SAVE')"
    :cancel-button-label="t('CRM_PRODUCTS.FORM.CANCEL')"
    :disable-confirm-button="isInvalid"
    :is-loading="isSaving"
    @confirm="save"
  >
    <div class="flex flex-col gap-4">
      <Input
        v-model="form.name"
        :label="t('CRM_PRODUCTS.FORM.NAME')"
        :placeholder="t('CRM_PRODUCTS.FORM.NAME_PLACEHOLDER')"
      />
      <label class="flex flex-col gap-1.5">
        <span class="text-label text-n-slate-12">
          {{ t('CRM_PRODUCTS.FORM.DESCRIPTION') }}
        </span>
        <textarea
          v-model="form.description"
          rows="2"
          :placeholder="t('CRM_PRODUCTS.FORM.DESCRIPTION_PLACEHOLDER')"
          class="reset-base px-3 py-2 text-sm rounded-lg border border-n-slate-6 bg-n-alpha-black2 text-n-slate-12 resize-y"
        />
      </label>
      <div class="grid grid-cols-2 gap-3">
        <Input
          v-model="form.price"
          type="number"
          min="0"
          step="0.01"
          :label="t('CRM_PRODUCTS.FORM.PRICE')"
          placeholder="0,00"
        />
        <Input
          v-model="form.sku"
          :label="t('CRM_PRODUCTS.FORM.SKU')"
          :placeholder="t('CRM_PRODUCTS.FORM.SKU_PLACEHOLDER')"
        />
      </div>
      <label class="flex items-center gap-2 text-sm text-n-slate-12">
        <input v-model="form.active" type="checkbox" class="size-4" />
        {{ t('CRM_PRODUCTS.FORM.ACTIVE') }}
      </label>
    </div>
  </Dialog>
</template>
