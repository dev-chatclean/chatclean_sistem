<script setup>
import { useI18n } from 'vue-i18n';
import Input from 'dashboard/components-next/input/Input.vue';
import TextArea from 'dashboard/components-next/textarea/TextArea.vue';
import { useClientMessage } from '../useClientMessage';

defineProps({
  variables: { type: Array, required: true },
});

const message = defineModel({ type: Object, required: true });

const SELECT_CLASS =
  'reset-base h-10 ps-3 pe-6 text-sm rounded-lg border border-n-slate-6 bg-n-alpha-black2 text-n-slate-12';

const { t } = useI18n();
const {
  whatsAppInboxes,
  templateOptions,
  findTemplate,
  templateBody,
  selectTemplate,
  messageError,
} = useClientMessage();
</script>

<template>
  <div class="flex flex-col gap-3">
    <div class="flex flex-col gap-1.5">
      <span class="text-sm text-n-slate-12">
        {{ t('CRM_DEALS.CLIENT_MESSAGE.TYPE.LABEL') }}
      </span>
      <select v-model="message.messageType" :class="SELECT_CLASS">
        <option value="text">
          {{ t('CRM_DEALS.CLIENT_MESSAGE.TYPE.TEXT') }}
        </option>
        <option value="template" :disabled="!whatsAppInboxes.length">
          {{ t('CRM_DEALS.CLIENT_MESSAGE.TYPE.TEMPLATE') }}
        </option>
      </select>
      <span class="text-label-small text-n-slate-11">
        {{
          message.messageType === 'text'
            ? t('CRM_DEALS.CLIENT_MESSAGE.TYPE.TEXT_HINT')
            : t('CRM_DEALS.CLIENT_MESSAGE.TYPE.TEMPLATE_HINT')
        }}
      </span>
    </div>

    <TextArea
      v-if="message.messageType === 'text'"
      v-model="message.content"
      :label="t('CRM_DEALS.CLIENT_MESSAGE.CONTENT')"
      :max-length="4096"
      auto-height
    />

    <template v-else>
      <label class="flex flex-col gap-1.5">
        <span class="text-sm text-n-slate-12">
          {{ t('CRM_DEALS.CLIENT_MESSAGE.TEMPLATE.INBOX') }}
        </span>
        <select v-model="message.inboxId" :class="SELECT_CLASS">
          <option
            v-for="inbox in whatsAppInboxes"
            :key="inbox.id"
            :value="inbox.id"
          >
            {{ inbox.name }}
          </option>
        </select>
      </label>
      <label class="flex flex-col gap-1.5">
        <span class="text-sm text-n-slate-12">
          {{ t('CRM_DEALS.CLIENT_MESSAGE.TEMPLATE.LABEL') }}
        </span>
        <select
          :value="
            message.templateName
              ? `${message.templateName}|${message.templateLanguage}`
              : ''
          "
          :class="SELECT_CLASS"
          @change="selectTemplate(message, $event.target.value)"
        >
          <option value="" disabled>
            {{ t('CRM_DEALS.CLIENT_MESSAGE.TEMPLATE.CHOOSE') }}
          </option>
          <option
            v-for="template in templateOptions(message.inboxId)"
            :key="`${template.name}|${template.language}`"
            :value="`${template.name}|${template.language}`"
          >
            {{ `${template.name} (${template.language})` }}
          </option>
        </select>
      </label>
      <p
        v-if="findTemplate(message)"
        class="px-3 py-2 m-0 text-sm rounded-lg bg-n-alpha-black2 text-n-slate-12 whitespace-pre-wrap"
      >
        {{ templateBody(findTemplate(message)) }}
      </p>
      <Input
        v-for="(_, key) in message.body"
        :key="key"
        v-model="message.body[key]"
        :label="t('CRM_DEALS.CLIENT_MESSAGE.TEMPLATE.VARIABLE', { key })"
        :placeholder="variables[0]"
      />
    </template>

    <span class="text-label-small text-n-slate-11">
      {{
        t('CRM_DEALS.CLIENT_MESSAGE.VARIABLES', {
          variables: variables.join(' '),
        })
      }}
    </span>
    <span v-if="messageError(message)" class="text-label-small text-n-ruby-11">
      {{ messageError(message) }}
    </span>
  </div>
</template>
