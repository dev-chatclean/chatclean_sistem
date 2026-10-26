// Mensagens rápidas por departamento e por usuário, com anexos (US 17).
export const VISIBILITY = {
  EVERYONE: 'everyone',
  TEAMS: 'teams',
  PERSONAL: 'personal',
};
export const MAX_ATTACHMENTS_SIZE = 16 * 1024 * 1024;

// Monta o envio do formulário. Vai como FormData por causa dos arquivos; departamentos só seguem
// quando o alcance é "Departamentos" (o servidor limpa nos outros casos).
export const buildCannedFormData = ({
  shortCode,
  content,
  visibility,
  teamIds = [],
  newFiles = [],
  removeAttachmentIds = [],
}) => {
  const formData = new FormData();
  formData.append('canned_response[short_code]', shortCode);
  formData.append('canned_response[content]', content);
  formData.append('canned_response[visibility]', visibility);
  if (visibility === VISIBILITY.TEAMS) {
    teamIds.forEach(id => formData.append('canned_response[team_ids][]', id));
  }
  newFiles.forEach(file =>
    formData.append('canned_response[attachments][]', file)
  );
  removeAttachmentIds.forEach(id =>
    formData.append('canned_response[remove_attachment_ids][]', id)
  );
  return formData;
};
