<script setup>
import { computed, onMounted, reactive, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import Button from 'dashboard/components-next/button/Button.vue';
import ComboBox from 'dashboard/components-next/combobox/ComboBox.vue';
import Select from 'dashboard/components-next/select/Select.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import Switch from 'dashboard/components-next/switch/Switch.vue';
import TextArea from 'dashboard/components-next/textarea/TextArea.vue';
import BusinessDay from '../inbox/components/BusinessDay.vue';
import {
  timeSlotParse,
  timeSlotTransform,
  timeZoneOptions,
} from '../inbox/helpers/businessHour';
import WorkingScheduleAPI from 'dashboard/api/chatclean/workingSchedule';

// Horário da conta (US 19): "por canal" mantém o horário de cada canal; "por conta" aplica este
// horário a todos os canais, inclusive os criados depois.
const DAY_KEYS = [
  'SUNDAY',
  'MONDAY',
  'TUESDAY',
  'WEDNESDAY',
  'THURSDAY',
  'FRIDAY',
  'SATURDAY',
];

const { t } = useI18n();
const isLoading = ref(true);
const isSaving = ref(false);
const form = reactive({
  mode: 'per_channel',
  enabled: false,
  timezone: 'America/Sao_Paulo',
  outOfOfficeMessage: '',
  timeSlots: [],
});

const modeOptions = computed(() => [
  {
    value: 'per_channel',
    label: t('CHATCLEAN.BUSINESS_HOURS.MODE.PER_CHANNEL'),
  },
  {
    value: 'per_account',
    label: t('CHATCLEAN.BUSINESS_HOURS.MODE.PER_ACCOUNT'),
  },
]);
const timeZones = timeZoneOptions();
const isPerAccount = computed(() => form.mode === 'per_account');
const hasError = computed(
  () => form.enabled && form.timeSlots.some(slot => slot.from && !slot.valid)
);

const load = schedule => {
  Object.assign(form, {
    mode: schedule.mode,
    enabled: schedule.enabled,
    timezone: schedule.timezone,
    outOfOfficeMessage: schedule.out_of_office_message || '',
    timeSlots: timeSlotParse(schedule.working_hours),
  });
};

const onSlotUpdate = (day, slot) => {
  form.timeSlots = form.timeSlots.map(item => (item.day === day ? slot : item));
};

const save = async () => {
  isSaving.value = true;
  try {
    const { data } = await WorkingScheduleAPI.save({
      mode: form.mode,
      enabled: form.enabled,
      timezone: form.timezone,
      out_of_office_message: form.outOfOfficeMessage,
      working_hours: timeSlotTransform(form.timeSlots),
    });
    load(data);
    useAlert(t('CHATCLEAN.BUSINESS_HOURS.SAVED'));
  } catch (error) {
    useAlert(
      error?.response?.data?.message || t('CHATCLEAN.BUSINESS_HOURS.ERROR')
    );
  } finally {
    isSaving.value = false;
  }
};

onMounted(async () => {
  try {
    const { data } = await WorkingScheduleAPI.show();
    load(data);
  } finally {
    isLoading.value = false;
  }
});
</script>

<template>
  <div v-if="isLoading" class="flex justify-center py-10">
    <Spinner />
  </div>
  <form v-else class="flex flex-col gap-6" @submit.prevent="save">
    <label class="flex flex-col gap-1.5 text-sm text-n-slate-12">
      {{ t('CHATCLEAN.BUSINESS_HOURS.MODE.LABEL') }}
      <Select
        v-model="form.mode"
        :options="modeOptions"
        class="!w-full [&_select]:w-full"
        data-test="schedule-mode"
      />
      <span class="text-n-slate-11">
        {{
          isPerAccount
            ? t('CHATCLEAN.BUSINESS_HOURS.MODE.PER_ACCOUNT_HINT')
            : t('CHATCLEAN.BUSINESS_HOURS.MODE.PER_CHANNEL_HINT')
        }}
      </span>
    </label>

    <template v-if="isPerAccount">
      <div class="flex items-center justify-between text-sm text-n-slate-12">
        {{ t('CHATCLEAN.BUSINESS_HOURS.ENABLED') }}
        <Switch v-model="form.enabled" data-test="schedule-enabled" />
      </div>
      <template v-if="form.enabled">
        <TextArea
          v-model="form.outOfOfficeMessage"
          :label="t('CHATCLEAN.BUSINESS_HOURS.MESSAGE')"
          :placeholder="t('CHATCLEAN.BUSINESS_HOURS.MESSAGE_PLACEHOLDER')"
          data-test="schedule-message"
        />
        <label class="flex flex-col gap-1.5 text-sm text-n-slate-12">
          {{ t('CHATCLEAN.BUSINESS_HOURS.TIMEZONE') }}
          <ComboBox
            v-model="form.timezone"
            :options="timeZones"
            data-test="schedule-timezone"
          />
        </label>
        <table
          class="min-w-full table-auto outline outline-1 -outline-offset-1 outline-n-weak rounded-xl"
        >
          <tbody class="divide-y divide-n-weak">
            <BusinessDay
              v-for="slot in form.timeSlots"
              :key="slot.day"
              :day-name="
                t(`CHATCLEAN.BUSINESS_HOURS.DAYS.${DAY_KEYS[slot.day]}`)
              "
              :time-slot="slot"
              @update="data => onSlotUpdate(slot.day, data)"
            />
          </tbody>
        </table>
      </template>
    </template>

    <div class="flex justify-end">
      <Button
        type="submit"
        :label="t('CHATCLEAN.BUSINESS_HOURS.SAVE')"
        :is-loading="isSaving"
        :disabled="hasError"
        data-test="schedule-save"
      />
    </div>
  </form>
</template>
