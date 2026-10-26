// Anexos de mensagem rápida no atendimento (US 17). Ao escolher a mensagem no "/", os arquivos são
// baixados e entram na resposta como anexos comuns: dá para remover antes de enviar, e a mensagem
// enviada guarda a própria cópia, mesmo se a mensagem rápida for excluída (CA 17.5 e 17.6).
export const CANNED_ATTACHMENTS_EVENT = 'chatclean:canned-attachments';

export const downloadCannedAttachments = attachments =>
  Promise.all(
    attachments.map(
      async ({ file_url: url, file_name: name, content_type: type }) => {
        const response = await fetch(url, { credentials: 'same-origin' });
        const blob = await response.blob();
        return new File([blob], name, { type });
      }
    )
  );
