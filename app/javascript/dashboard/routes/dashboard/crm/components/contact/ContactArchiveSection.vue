<script setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { useStore } from 'dashboard/composables/store';
import ContactArchivesAPI from 'dashboard/api/contactArchives';
import CrmDealsAPI from 'dashboard/api/crm/deals';
import Button from 'dashboard/components-next/button/Button.vue';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';

const props = defineProps({
  contact: { type: Object, required: true },
  // In the contact list the contact leaves the current view after the change.
  inList: { type: Boolean, default: false },
});

const { t } = useI18n();
const store = useStore();

const dialogRef = ref(null);
const openDealsCount = ref(0);
const isSaving = ref(false);

const isArchived = computed(() => Boolean(props.contact.archivedAt));

const refreshContact = () =>
  props.inList
    ? store.commit('contacts/DELETE_CONTACT', props.contact.id)
    : store.dispatch('contacts/show', { id: props.contact.id });

const askArchive = async () => {
  const { data } = await CrmDealsAPI.forContact(props.contact.id);
  openDealsCount.value = data.payload.filter(
    deal => deal.status === 'open'
  ).length;
  dialogRef.value?.open();
};

const archive = async () => {
  isSaving.value = true;
  try {
    await ContactArchivesAPI.archive(props.contact.id);
    dialogRef.value?.close();
    useAlert(t('CRM_DEALS.ARCHIVE.ARCHIVED'));
    await refreshContact();
  } catch (error) {
    useAlert(t('CRM_DEALS.ARCHIVE.ERROR'));
  } finally {
    isSaving.value = false;
  }
};

const unarchive = async () => {
  isSaving.value = true;
  try {
    await ContactArchivesAPI.unarchive(props.contact.id);
    useAlert(t('CRM_DEALS.ARCHIVE.UNARCHIVED'));
    await refreshContact();
  } catch (error) {
    useAlert(t('CRM_DEALS.ARCHIVE.ERROR'));
  } finally {
    isSaving.value = false;
  }
};
</script>

<template>
  <div
    class="flex flex-col items-start w-full gap-4 border-t border-n-strong"
    :class="inList ? 'px-6 py-5' : 'pt-6'"
  >
    <div class="flex flex-col gap-2">
      <h6
        class="flex items-center gap-2 m-0 text-base font-medium text-n-slate-12"
      >
        {{ t('CRM_DEALS.ARCHIVE.TITLE') }}
        <span
          v-if="isArchived"
          class="px-2 py-0.5 text-label-small rounded-md bg-n-amber-3 text-n-amber-11"
        >
          {{ t('CRM_DEALS.ARCHIVE.BADGE') }}
        </span>
      </h6>
      <span class="text-sm text-n-slate-11">
        {{
          isArchived
            ? t('CRM_DEALS.ARCHIVE.ARCHIVED_DESCRIPTION')
            : t('CRM_DEALS.ARCHIVE.DESCRIPTION')
        }}
      </span>
    </div>
    <Button
      v-if="isArchived"
      :label="t('CRM_DEALS.ARCHIVE.UNARCHIVE')"
      slate
      :is-loading="isSaving"
      @click="unarchive"
    />
    <Button
      v-else
      :label="t('CRM_DEALS.ARCHIVE.ARCHIVE')"
      slate
      :is-loading="isSaving"
      @click="askArchive"
    />
    <Dialog
      ref="dialogRef"
      type="alert"
      :title="t('CRM_DEALS.ARCHIVE.CONFIRM_TITLE')"
      :description="
        openDealsCount
          ? t(
              'CRM_DEALS.ARCHIVE.CONFIRM_OPEN_DEALS',
              { count: openDealsCount },
              openDealsCount
            )
          : t('CRM_DEALS.ARCHIVE.CONFIRM')
      "
      :confirm-button-label="t('CRM_DEALS.ARCHIVE.ARCHIVE')"
      :cancel-button-label="t('CRM_DEALS.ACTIVITY.CANCEL')"
      :is-loading="isSaving"
      @confirm="archive"
    />
  </div>
</template>
