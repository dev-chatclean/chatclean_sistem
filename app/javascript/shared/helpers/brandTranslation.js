// ChatClean (CCV2-48): os textos traduzidos do Chatwoot citam "Chatwoot" em muitos lugares que não
// passam pelo replaceInstallationName. Aqui toda tradução da tela troca o nome pelo da instalação.
export const replaceBrandInTranslation = message => {
  const installationName = window.globalConfig?.INSTALLATION_NAME;
  if (!installationName || typeof message !== 'string') return message;
  return message.replace(/Chatwoot/g, installationName);
};
