import { INBOX_TYPES } from 'dashboard/helper/inbox';

// Canais que mostrariam os asteriscos do negrito como texto (o Chatwoot não converte para eles).
const PLAIN_TEXT_CHANNELS = [
  INBOX_TYPES.FB,
  INBOX_TYPES.INSTAGRAM,
  INBOX_TYPES.TIKTOK,
];

// Assinatura do atendente (US 18): o nome de exibição (ou o nome) em negrito na primeira linha da
// mensagem enviada. Os dois espaços antes da quebra fazem o texto começar na linha seguinte em todos
// os canais. Mensagem sem texto (só arquivo) segue sem o nome.
export const withAgentName = (message, { user, channelType }) => {
  if (!message?.trim()) return message;

  const name = user.display_name || user.name;
  const label = PLAIN_TEXT_CHANNELS.includes(channelType)
    ? `${name}:`
    : `**${name}:**`;
  return `${label}  \n${message}`;
};
