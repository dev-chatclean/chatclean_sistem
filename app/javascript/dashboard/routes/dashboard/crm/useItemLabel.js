import { useI18n } from 'vue-i18n';

export function useItemLabel() {
  const { t } = useI18n();

  const itemLabel = (pipeline, count = 1) => {
    if (pipeline?.item_label === 'custom') return pipeline.item_label_custom;
    const key = pipeline?.item_label || 'deal';
    return t(`CRM_PIPELINES.ITEM_LABELS.${key}`, count);
  };

  return { itemLabel };
}
