<script setup>
import { computed, onMounted, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import CrmProductsAPI from 'dashboard/api/crm/products';
import { formatCurrency } from '../../dealHelpers';
import { MAX_PRODUCT_QUANTITY } from '../../constants';

const props = defineProps({
  items: { type: Array, default: () => [] },
});

const emit = defineEmits(['add', 'change', 'remove']);

const { t } = useI18n();

const catalog = ref([]);
const selectedId = ref('');

const available = computed(() => {
  const used = props.items.map(item => item.product_id);
  return catalog.value.filter(
    product => product.active && !used.includes(product.id)
  );
});
const total = computed(() =>
  props.items.reduce((sum, item) => sum + item.quantity * item.unit_price, 0)
);

const add = () => {
  const product = catalog.value.find(item => item.id === selectedId.value);
  if (!product) return;
  emit('add', product);
  selectedId.value = '';
};

const changeQuantity = (item, value) => {
  const quantity = Math.min(
    Math.max(Math.floor(Number(value)) || 1, 1),
    MAX_PRODUCT_QUANTITY
  );
  if (quantity !== item.quantity) emit('change', item, { quantity });
};

const changePrice = (item, value) => {
  const unitPrice = Math.max(Number(value) || 0, 0);
  if (unitPrice !== item.unit_price)
    emit('change', item, { unit_price: unitPrice });
};

onMounted(async () => {
  const { data } = await CrmProductsAPI.get();
  catalog.value = data.payload;
});
</script>

<template>
  <div class="flex flex-col gap-2">
    <p v-if="!catalog.length" class="m-0 text-sm text-n-slate-11">
      {{ t('CRM_DEALS.DETAIL.NO_PRODUCTS') }}
    </p>
    <template v-else>
      <ul v-if="items.length" class="flex flex-col gap-2 p-0 m-0 list-none">
        <li
          v-for="item in items"
          :key="item.id || item.product_id"
          class="grid items-center gap-2 grid-cols-[minmax(0,1fr)_4.5rem_7rem_6.5rem_2rem]"
        >
          <span class="text-sm truncate text-n-slate-12">{{ item.name }}</span>
          <input
            type="number"
            min="1"
            :max="MAX_PRODUCT_QUANTITY"
            :value="item.quantity"
            :aria-label="t('CRM_DEALS.PRODUCTS.QUANTITY')"
            class="reset-base h-9 px-2 text-sm rounded-lg border border-n-slate-6 bg-n-alpha-black2 text-n-slate-12"
            @change="changeQuantity(item, $event.target.value)"
          />
          <input
            type="number"
            min="0"
            step="0.01"
            :value="item.unit_price"
            :aria-label="t('CRM_DEALS.PRODUCTS.UNIT_PRICE')"
            class="reset-base h-9 px-2 text-sm rounded-lg border border-n-slate-6 bg-n-alpha-black2 text-n-slate-12"
            @change="changePrice(item, $event.target.value)"
          />
          <span class="text-sm font-medium text-end text-n-slate-12">
            {{ formatCurrency(item.quantity * item.unit_price) }}
          </span>
          <button
            type="button"
            class="flex items-center justify-center rounded-lg size-8 text-n-slate-11 hover:bg-n-alpha-2 hover:text-n-ruby-11"
            :aria-label="t('CRM_DEALS.PRODUCTS.REMOVE')"
            @click="emit('remove', item)"
          >
            <span class="i-lucide-x size-4" />
          </button>
        </li>
      </ul>
      <div class="flex gap-2">
        <select
          v-model="selectedId"
          class="reset-base flex-1 min-w-0 h-9 px-3 text-sm rounded-lg border border-n-slate-6 bg-n-alpha-black2 text-n-slate-12"
          :aria-label="t('CRM_DEALS.PRODUCTS.ADD')"
          @change="add"
        >
          <option value="" disabled>{{ t('CRM_DEALS.PRODUCTS.ADD') }}</option>
          <option
            v-for="product in available"
            :key="product.id"
            :value="product.id"
          >
            {{ product.name }} · {{ formatCurrency(product.price) }}
          </option>
        </select>
      </div>
      <p
        v-if="items.length"
        class="flex justify-between m-0 text-sm text-n-slate-11"
      >
        <span>{{ t('CRM_DEALS.PRODUCTS.TOTAL') }}</span>
        <span class="font-medium text-n-slate-12">{{
          formatCurrency(total)
        }}</span>
      </p>
    </template>
  </div>
</template>
