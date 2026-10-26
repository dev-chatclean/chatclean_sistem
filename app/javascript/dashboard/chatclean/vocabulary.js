// Vocabulário da ChatClean atual no painel em pt_BR (US 14, CCV2-29). O arquivo
// pt_BR/chatcleanVocabulary.json guarda só as frases que mudam (Atendimento, Canal,
// Departamento, Atendente, Mensagem rápida, Campo customizado, Plugins, Envios), e elas são
// aplicadas por cima das traduções do Chatwoot. Assim as frases novas de uma atualização do
// Chatwoot continuam aparecendo; o teste do vocabulário aponta as que ainda usam os termos antigos.
const isObject = value =>
  value !== null && typeof value === 'object' && !Array.isArray(value);

export const withVocabulary = (messages, vocabulary) => {
  const merged = { ...messages };
  Object.entries(vocabulary).forEach(([key, value]) => {
    merged[key] =
      isObject(value) && isObject(messages[key])
        ? withVocabulary(messages[key], value)
        : value;
  });
  return merged;
};
