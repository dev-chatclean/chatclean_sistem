import { useI18n } from 'vue-i18n';
import { useMapGetter } from 'dashboard/composables/store';

const PLACEHOLDER_PATTERN = /{{\s*([^}]+?)\s*}}/g;

// A message to the deal's contact: free text or an approved WhatsApp template (impulses and client reminders).
export const useClientMessage = () => {
  const { t } = useI18n();
  const whatsAppInboxes = useMapGetter('inboxes/getWhatsAppInboxes');
  const templatesFor = useMapGetter('inboxes/getFilteredWhatsAppTemplates');

  const templateOptions = inboxId =>
    inboxId ? templatesFor.value(inboxId) : [];

  const findTemplate = message =>
    templateOptions(message.inboxId).find(
      item =>
        item.name === message.templateName &&
        item.language === message.templateLanguage
    );

  const templateBody = template =>
    template?.components?.find(component => component.type === 'BODY')?.text ||
    '';

  const templatePlaceholders = template => [
    ...new Set(
      [...templateBody(template).matchAll(PLACEHOLDER_PATTERN)].map(
        match => match[1]
      )
    ),
  ];

  // The template is chosen from a WhatsApp inbox; at send time it is looked up in the conversation's inbox.
  const inboxWithTemplate = (name, language) =>
    whatsAppInboxes.value.find(inbox =>
      templatesFor
        .value(inbox.id)
        .some(item => item.name === name && item.language === language)
    )?.id ?? whatsAppInboxes.value[0]?.id;

  const buildMessage = ({
    message_type: messageType,
    content,
    template_params: params = {},
  } = {}) => ({
    messageType: messageType || 'text',
    content: content || '',
    inboxId: inboxWithTemplate(params.name, params.language),
    templateName: params.name || '',
    templateLanguage: params.language || '',
    templateCategory: params.category || '',
    body: { ...(params.processed_params?.body || {}) },
  });

  const selectTemplate = (message, key) => {
    const [name, language] = key.split('|');
    const template = templateOptions(message.inboxId).find(
      item => item.name === name && item.language === language
    );
    message.templateName = name;
    message.templateLanguage = language;
    message.templateCategory = template?.category || '';
    message.body = Object.fromEntries(
      templatePlaceholders(template).map(placeholder => [placeholder, ''])
    );
  };

  const messageError = message => {
    if (message.messageType === 'text') {
      return message.content.trim()
        ? ''
        : t('CRM_DEALS.CLIENT_MESSAGE.ERRORS.CONTENT');
    }
    if (!message.templateName) {
      return t('CRM_DEALS.CLIENT_MESSAGE.ERRORS.TEMPLATE');
    }
    return Object.values(message.body).some(value => !value.trim())
      ? t('CRM_DEALS.CLIENT_MESSAGE.ERRORS.VARIABLES')
      : '';
  };

  const messagePayload = message => ({
    message_type: message.messageType,
    content: message.messageType === 'text' ? message.content.trim() : null,
    template_params:
      message.messageType === 'template'
        ? {
            name: message.templateName,
            language: message.templateLanguage,
            category: message.templateCategory,
            processed_params: { body: message.body },
          }
        : {},
  });

  return {
    whatsAppInboxes,
    templateOptions,
    findTemplate,
    templateBody,
    buildMessage,
    selectTemplate,
    messageError,
    messagePayload,
  };
};
