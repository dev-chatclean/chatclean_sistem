<script setup>
import { computed, onMounted, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { parseAPIErrorResponse } from 'dashboard/store/utils/api';
import CrmProductsAPI from 'dashboard/api/crm/products';
import BaseSettingsHeader from '../../settings/components/BaseSettingsHeader.vue';
import SettingsLayout from '../../settings/SettingsLayout.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import {
  BaseTable,
  BaseTableRow,
  BaseTableCell,
} from 'dashboard/components-next/table';
import ProductFormDialog from '../components/settings/ProductFormDialog.vue';
import { formatCurrency } from '../dealHelpers';

const { t } = useI18n();

const products = ref([]);
const isLoading = ref(true);
const searchQuery = ref('');
const formRef = ref(null);
const deleteDialogRef = ref(null);
const productToDelete = ref(null);

const filteredProducts = computed(() => {
  const term = searchQuery.value.trim().toLowerCase();
  if (!term) return products.value;
  return products.value.filter(product =>
    [product.name, product.sku, product.description]
      .join(' ')
      .toLowerCase()
      .includes(term)
  );
});

const tableHeaders = computed(() => [
  t('CRM_PRODUCTS.TABLE.NAME'),
  t('CRM_PRODUCTS.TABLE.PRICE'),
  t('CRM_PRODUCTS.TABLE.STATUS'),
  t('CRM_PRODUCTS.TABLE.ACTIONS'),
]);

const load = async () => {
  try {
    const { data } = await CrmProductsAPI.get();
    products.value = data.payload;
  } catch (error) {
    useAlert(t('CRM_PRODUCTS.API.FETCH_ERROR'));
  } finally {
    isLoading.value = false;
  }
};

const askDelete = product => {
  productToDelete.value = product;
  deleteDialogRef.value?.open();
};

const confirmDelete = async () => {
  try {
    await CrmProductsAPI.delete(productToDelete.value.id);
    useAlert(t('CRM_PRODUCTS.API.DELETE_SUCCESS'));
    deleteDialogRef.value?.close();
    await load();
  } catch (error) {
    const message = parseAPIErrorResponse(error);
    deleteDialogRef.value?.close();
    useAlert(
      typeof message === 'string' ? message : t('CRM_PRODUCTS.API.SAVE_ERROR')
    );
  }
};

onMounted(load);
</script>

<template>
  <SettingsLayout
    :is-loading="isLoading"
    :loading-message="t('CRM_PRODUCTS.LOADING')"
    :no-records-found="!products.length"
    :no-records-message="t('CRM_PRODUCTS.EMPTY')"
  >
    <template #header>
      <BaseSettingsHeader
        v-model:search-query="searchQuery"
        :title="t('CRM_PRODUCTS.HEADER')"
        :description="t('CRM_PRODUCTS.DESCRIPTION')"
        :search-placeholder="t('CRM_PRODUCTS.SEARCH_PLACEHOLDER')"
      >
        <template v-if="products.length" #count>
          <span class="text-body-main text-n-slate-11">
            {{ t('CRM_PRODUCTS.COUNT', { n: products.length }) }}
          </span>
        </template>
        <template #actions>
          <Button
            :label="t('CRM_PRODUCTS.NEW')"
            size="sm"
            @click="formRef.open()"
          />
        </template>
      </BaseSettingsHeader>
    </template>
    <template #body>
      <BaseTable
        :headers="tableHeaders"
        :items="filteredProducts"
        :no-data-message="t('CRM_PRODUCTS.NO_RESULTS')"
      >
        <template #row="{ items }">
          <BaseTableRow
            v-for="product in items"
            :key="product.id"
            :item="product"
          >
            <template #default>
              <BaseTableCell class="w-full">
                <span class="flex flex-col">
                  <span class="text-body-main text-n-slate-12">
                    {{ product.name }}
                  </span>
                  <span
                    v-if="product.sku || product.description"
                    class="text-label-small text-n-slate-11"
                  >
                    {{
                      [product.sku, product.description]
                        .filter(Boolean)
                        .join(' · ')
                    }}
                  </span>
                </span>
              </BaseTableCell>
              <BaseTableCell class="whitespace-nowrap">
                <span class="text-body-main text-n-slate-12">
                  {{ formatCurrency(product.price) }}
                </span>
              </BaseTableCell>
              <BaseTableCell class="whitespace-nowrap">
                <span
                  class="px-2 py-0.5 rounded-md text-label-small"
                  :class="
                    product.active
                      ? 'bg-n-teal-3 text-n-teal-11'
                      : 'bg-n-slate-3 text-n-slate-11'
                  "
                >
                  {{
                    product.active
                      ? t('CRM_PRODUCTS.ACTIVE')
                      : t('CRM_PRODUCTS.INACTIVE')
                  }}
                </span>
              </BaseTableCell>
              <BaseTableCell align="end">
                <div class="flex justify-end gap-3">
                  <Button
                    v-tooltip.top="t('CRM_PRODUCTS.EDIT')"
                    icon="i-woot-edit-pen"
                    slate
                    sm
                    @click="formRef.open(product)"
                  />
                  <Button
                    v-tooltip.top="t('CRM_PRODUCTS.DELETE')"
                    icon="i-woot-bin"
                    slate
                    sm
                    class="hover:enabled:text-n-ruby-11 hover:enabled:bg-n-ruby-2"
                    @click="askDelete(product)"
                  />
                </div>
              </BaseTableCell>
            </template>
          </BaseTableRow>
        </template>
      </BaseTable>
    </template>
  </SettingsLayout>
  <ProductFormDialog ref="formRef" @saved="load" />
  <Dialog
    ref="deleteDialogRef"
    type="alert"
    :title="t('CRM_PRODUCTS.DELETE')"
    :description="
      t('CRM_PRODUCTS.DELETE_CONFIRM', { name: productToDelete?.name || '' })
    "
    :confirm-button-label="t('CRM_PRODUCTS.DELETE')"
    :cancel-button-label="t('CRM_PRODUCTS.FORM.CANCEL')"
    @confirm="confirmDelete"
  />
</template>
