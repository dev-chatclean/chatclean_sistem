<script setup>
import { computed, nextTick, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRoute } from 'vue-router';
import { conversationUrl, frontendURL } from 'dashboard/helper/URLHelper';
import { formatCurrency, isClosingStage } from '../../../dealHelpers';
import { entryDuration, formatDateTime, formatDuration } from './dealTime';
import ProductsEditor from '../ProductsEditor.vue';

const props = defineProps({
  deal: { type: Object, required: true },
  pipeline: { type: Object, required: true },
  showValue: { type: Boolean, default: true },
});

const emit = defineEmits(['update']);

const { t, locale } = useI18n();
const route = useRoute();

const isEditingValue = ref(false);
const valueDraft = ref('');
const valueInput = ref(null);

const openStages = computed(() =>
  props.pipeline.stages.filter(stage => !isClosingStage(stage))
);
const stageColor = name =>
  props.pipeline.stages.find(stage => stage.name === name)?.color;

const timeByStage = computed(() => {
  const totals = {};
  props.deal.journey.forEach(entry => {
    totals[entry.stage_name] =
      (totals[entry.stage_name] || 0) + entryDuration(entry);
  });
  return totals;
});

const hasProducts = computed(() => props.deal.products.length > 0);

const addProduct = product =>
  emit('update', {
    deal_products_attributes: [{ product_id: product.id, quantity: 1 }],
  });

const changeProduct = (item, changes) =>
  emit('update', { deal_products_attributes: [{ id: item.id, ...changes }] });

const removeProduct = item =>
  emit('update', {
    deal_products_attributes: [{ id: item.id, _destroy: true }],
  });

const editValue = async () => {
  valueDraft.value = String(props.deal.value);
  isEditingValue.value = true;
  await nextTick();
  valueInput.value?.focus();
};

const saveValue = () => {
  if (!isEditingValue.value) return;
  isEditingValue.value = false;
  const value = Number(valueDraft.value) || 0;
  if (value !== props.deal.value) emit('update', { value });
};

const leadOriginText = computed(() => {
  const { lead_origin: origin, lead_source: source, conversation } = props.deal;
  const where = origin
    ? t(`CRM_PIPELINES.LEAD_ENTRY.OPTIONS.${origin.toUpperCase()}`)
    : conversation.inbox_name;
  return [where, t(`CRM_PIPELINES.LEAD_ENTRY.OPTIONS.${source.toUpperCase()}`)]
    .filter(Boolean)
    .join(' · ');
});

const leadConversationLink = computed(() =>
  frontendURL(
    conversationUrl({
      accountId: route.params.accountId,
      id: props.deal.conversation.display_id,
    })
  )
);

const valueParts = computed(() => {
  const text = formatCurrency(props.deal.value);
  return { symbol: 'R$', amount: text.replace(/^R\$\s?/, '') };
});
</script>

<template>
  <div class="flex flex-col gap-7">
    <div
      v-if="showValue"
      class="flex items-center justify-between gap-3 px-6 py-5 border rounded-2xl border-n-slate-6"
    >
      <div class="flex flex-col gap-2">
        <span class="text-sm text-n-slate-11">{{
          t('CRM_DEALS.DETAIL.DEAL_VALUE')
        }}</span>
        <input
          v-if="isEditingValue"
          ref="valueInput"
          v-model="valueDraft"
          type="number"
          min="0"
          step="0.01"
          class="reset-base w-48 h-10 px-3 text-xl font-semibold rounded-lg border border-n-brand bg-transparent text-n-slate-12"
          @blur="saveValue"
          @keydown.enter="saveValue"
          @keydown.esc="isEditingValue = false"
        />
        <span v-else class="flex items-baseline gap-1.5 text-n-slate-12">
          <span class="text-lg font-semibold text-n-slate-11">{{
            valueParts.symbol
          }}</span>
          <span class="text-2xl font-semibold">{{ valueParts.amount }}</span>
        </span>
      </div>
      <span v-if="hasProducts" class="text-label-small text-n-slate-11">
        {{ t('CRM_DEALS.PRODUCTS.VALUE_FROM_PRODUCTS') }}
      </span>
      <button
        v-else
        type="button"
        class="flex items-center justify-center rounded-lg size-9 text-n-slate-11 hover:bg-n-alpha-2 hover:text-n-slate-12"
        :aria-label="t('CRM_DEALS.DETAIL.EDIT_VALUE')"
        @click="editValue"
      >
        <span class="i-lucide-pencil size-4" />
      </button>
    </div>

    <section class="flex flex-col gap-2">
      <h3 class="text-sm font-medium text-n-slate-11">
        {{ t('CRM_DEALS.DETAIL.PRODUCTS') }}
      </h3>
      <ProductsEditor
        :items="deal.products"
        @add="addProduct"
        @change="changeProduct"
        @remove="removeProduct"
      />
    </section>

    <section class="flex flex-col gap-4">
      <h3 class="text-sm font-medium text-n-slate-11">
        {{ t('CRM_DEALS.DETAIL.FULL_PIPELINE') }}
      </h3>
      <ol class="relative flex p-0 m-0 list-none">
        <li
          v-for="(stage, index) in openStages"
          :key="stage.id"
          class="relative flex flex-col items-center flex-1 gap-1.5 min-w-0 text-center"
        >
          <span
            v-if="index < openStages.length - 1"
            class="absolute top-3 h-px bg-n-slate-6 start-1/2 w-full"
          />
          <span
            class="relative z-10 flex items-center justify-center rounded-full size-6 border-2 bg-n-solid-1"
            :class="
              stage.id === deal.stage_id
                ? 'border-n-blue-9'
                : 'border-n-slate-6'
            "
          >
            <span
              v-if="stage.id === deal.stage_id"
              class="rounded-full size-2.5 bg-n-blue-9"
            />
          </span>
          <span
            class="text-sm truncate max-w-full"
            :class="
              stage.id === deal.stage_id
                ? 'font-semibold text-n-slate-12'
                : 'text-n-slate-11'
            "
          >
            {{ stage.name }}
          </span>
          <span
            v-if="timeByStage[stage.name]"
            class="text-label-small text-n-slate-11"
          >
            {{ formatDuration(timeByStage[stage.name], t) }}
          </span>
        </li>
      </ol>
    </section>

    <section class="flex flex-col gap-1">
      <h3 class="text-sm font-medium text-n-slate-11">
        {{ t('CRM_DEALS.DETAIL.DEAL_INFO') }}
      </h3>
      <dl class="flex flex-col m-0 divide-y divide-n-weak">
        <div class="flex justify-between py-3 text-sm">
          <dt class="text-n-slate-11">{{ t('CRM_DEALS.DETAIL.NUMBER') }}</dt>
          <dd class="m-0 font-semibold text-n-slate-12">
            {{ t('CRM_DEALS.NUMBER', { number: deal.number }) }}
          </dd>
        </div>
        <div class="flex justify-between py-3 text-sm">
          <dt class="text-n-slate-11">
            {{ t('CRM_DEALS.DETAIL.CREATED_AT') }}
          </dt>
          <dd class="m-0 font-semibold text-n-slate-12">
            {{ formatDateTime(deal.created_at, locale) }}
          </dd>
        </div>
        <div class="flex justify-between py-3 text-sm">
          <dt class="text-n-slate-11">
            {{ t('CRM_DEALS.DETAIL.IN_STAGE_SINCE') }}
          </dt>
          <dd class="m-0 font-semibold text-n-slate-12">
            {{ formatDateTime(deal.stage_entered_at, locale) }}
          </dd>
        </div>
        <div v-if="deal.conversation" class="flex justify-between py-3 text-sm">
          <dt class="text-n-slate-11">
            {{ t('CRM_DEALS.DETAIL.LEAD_ORIGIN') }}
          </dt>
          <dd class="flex items-center gap-2 m-0 font-semibold text-n-slate-12">
            {{ leadOriginText }}
            <router-link
              :to="leadConversationLink"
              class="font-normal text-n-brand hover:underline"
            >
              {{
                t('CRM_DEALS.DETAIL.LEAD_CONVERSATION', {
                  number: deal.conversation.display_id,
                })
              }}
            </router-link>
          </dd>
        </div>
      </dl>
    </section>

    <section class="flex flex-col gap-3">
      <h3 class="text-sm font-medium text-n-slate-11">
        {{ t('CRM_DEALS.DETAIL.JOURNEY') }}
      </h3>
      <ol class="flex flex-col gap-4 p-0 m-0 list-none">
        <li
          v-for="(entry, index) in deal.journey"
          :key="`${entry.entered_at}-${index}`"
          class="flex items-start justify-between gap-3"
        >
          <div class="flex items-start gap-3">
            <span
              class="mt-1.5 rounded-full size-2.5 shrink-0"
              :style="{
                backgroundColor: stageColor(entry.stage_name) || 'currentColor',
              }"
            />
            <div class="flex flex-col gap-0.5">
              <span class="text-base font-medium text-n-slate-12">{{
                entry.stage_name
              }}</span>
              <span class="text-sm text-n-slate-11">
                {{
                  t('CRM_DEALS.DETAIL.RANGE', {
                    from: formatDateTime(entry.entered_at, locale),
                    to: entry.left_at
                      ? formatDateTime(entry.left_at, locale)
                      : t('CRM_DEALS.DETAIL.NOW'),
                  })
                }}
              </span>
            </div>
          </div>
          <span class="text-sm text-n-slate-11 shrink-0">
            {{ formatDuration(entryDuration(entry), t) }}
          </span>
        </li>
      </ol>
    </section>
  </div>
</template>
