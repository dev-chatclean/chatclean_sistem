import ptBR from 'dashboard/i18n/locale/pt_BR';
import chatcleanVocabulary from 'dashboard/i18n/locale/pt_BR/chatcleanVocabulary.json';
import { withVocabulary } from '../vocabulary';

// Termos do Chatwoot que o painel em pt_BR não usa mais (US 14, CCV2-29).
const OLD_TERMS =
  /\b(conversas?|caixas? de entrada|times?|agentes?|respostas? prontas?|atributos? personalizados?|aplicativos? do painel|campanhas?)\b/i;

// Usos que continuam com o termo: e-mail do próprio usuário, notificações, o time do Linear,
// o robô (agente bot), conversas do WhatsApp, o botão do widget, que tem tradução própria, e o time inteiro.
const ALLOWED = [
  'REGISTER.VERIFY_EMAIL.TITLE',
  'REGISTER.VERIFY_EMAIL.RESEND_SUCCESS',
  'APP_GLOBAL.EMAIL_VERIFICATION_PENDING',
  'APP_GLOBAL.EMAIL_VERIFICATION_SENT',
  'SIDEBAR.INBOX_VIEW',
  'SIDEBAR.INBOX',
  'INBOX.LIST.TITLE',
  'INTEGRATION_SETTINGS.LINEAR.LOADING_ERROR',
  'INTEGRATION_SETTINGS.LINEAR.ADD_OR_LINK.FORM.TEAM.LABEL',
  'INTEGRATION_SETTINGS.LINEAR.ADD_OR_LINK.FORM.TEAM.PLACEHOLDER',
  'INTEGRATION_SETTINGS.LINEAR.ADD_OR_LINK.FORM.TEAM.SEARCH',
  'INTEGRATION_SETTINGS.LINEAR.ADD_OR_LINK.FORM.TEAM.REQUIRED_ERROR',
  'INTEGRATION_SETTINGS.LINEAR.ADD_OR_LINK.LOADING_TEAM_ERROR',
  'INTEGRATION_SETTINGS.LINEAR.ADD_OR_LINK.LOADING_TEAM_ENTITIES_ERROR',
  'COMMAND_BAR.COMMANDS.GO_TO_MY_INBOX',
  'AGENT_BOTS.DESCRIPTION',
  'AGENT_BOTS.LEARN_MORE',
  'AGENT_BOTS.BOT_CONFIGURATION.TITLE',
  'AGENT_BOTS.BOT_CONFIGURATION.DESC',
  'AGENT_BOTS.BOT_CONFIGURATION.SUCCESS_MESSAGE',
  'AGENT_BOTS.BOT_CONFIGURATION.ERROR_MESSAGE',
  'AGENT_BOTS.BOT_CONFIGURATION.DISCONNECTED_ERROR_MESSAGE',
  'AGENT_BOTS.ADD.API.ERROR_MESSAGE',
  'INBOX_MGMT.ADD.EMAIL_CHANNEL.DESC',
  'INBOX_MGMT.ACCOUNT_HEALTH.FIELDS.DISPLAY_NAME_STATUS.DESCRIPTIONS.APPROVED',
  'INBOX_MGMT.WIDGET_BUILDER.FOOTER.START_CONVERSATION_BUTTON_TEXT',
  // Subtítulo do "Criar atendimento" no texto da ChatClean atual (US 15).
  'CHATCLEAN.START_CONVERSATION.DESCRIPTION',
  // "Time" no sentido do time inteiro, e não de departamento, fica como no Chatwoot (decisão do PO, 26/10/2026).
  'INTEGRATION_SETTINGS.DESCRIPTION',
  'INTEGRATION_SETTINGS.SLACK.HELP_TEXT.BODY_ALERT',
  'CAPTAIN.OVERVIEW.METRICS.HANDLED.HINT',
  'CAPTAIN.OVERVIEW.METRICS.AUTO_RESOLUTION.HINT',
  'CAPTAIN.OVERVIEW.METRICS.HANDOFF.HINT',
  'CAPTAIN.OVERVIEW.V2.RESOLUTION_FLOW.ARIA_LABEL',
  'CAPTAIN.OVERVIEW.V2.RESOLUTION_FLOW.NODES.CLOSED_WITH_TEAM',
  'CAPTAIN.OVERVIEW.V2.CSAT.AUTONOMOUS_HINT',
  'CONVERSATION.VISIBLE_TO_AGENTS',
  'SLA.DESCRIPTION',
  'TEAMS_SETTINGS.CREATE_FLOW.AGENTS.DESC',
  'TEAMS_SETTINGS.ADD.DESC',
  'TEAMS_SETTINGS.FINISH.MESSAGE',
  'AGENT_MGMT.DESCRIPTION',
  'AGENT_MGMT.LIST.TITLE',
  'AGENT_MGMT.LIST.DESC',
  'AGENT_MGMT.ADD.TITLE',
  'AUTOMATION.DESCRIPTION',
  'BILLING_SETTINGS.DESCRIPTION',
  // "time" no sentido do time inteiro em textos traduzidos na revisão de tradução (CCV2-29).
  'INTEGRATION_SETTINGS.SHOPIFY.HELP_TEXT.BODY',
  'MONITORS.TEMPLATES.LOGIN_PROBLEMS.AUDIENCE',
  'MONITORS.TEMPLATES.MISSING_ORDER_UPDATES.AUDIENCE',
  'MONITORS.TEMPLATES.COMPETITOR_MENTIONS.AUDIENCE',
  'MONITORS.TEMPLATES.FEATURE_REQUESTS.AUDIENCE',
  'MONITORS.TEMPLATES.REFUND_REQUESTS.AUDIENCE',
  'MONITORS.TEMPLATES.PAYMENT_FAILURES.AUDIENCE',
  'MONITORS.TEMPLATES.PRODUCT_ERRORS.AUDIENCE',
];

const texts = (node, path = []) =>
  typeof node === 'string'
    ? [[path.join('.'), node]]
    : Object.entries(node).flatMap(([key, value]) =>
        texts(value, [...path, key])
      );

describe('ChatClean vocabulary', () => {
  it('leaves no Chatwoot term in the pt_BR dashboard', () => {
    const remaining = texts(ptBR)
      .filter(([, text]) => OLD_TERMS.test(text.replace(/\{[^}]*\}/g, '')))
      .map(([key]) => key)
      .filter(key => !ALLOWED.includes(key));

    // Uma atualização do Chatwoot trouxe frases novas: reescreva-as em chatcleanVocabulary.json.
    expect(remaining).toEqual([]);
  });

  // Vale contra os textos do Chatwoot em inglês e em português: o vocabulário também traduz frases
  // que ainda não têm tradução em português no Chatwoot.
  it('only rewrites texts that still exist in the Chatwoot texts', () => {
    const files = {
      ...import.meta.glob('../../i18n/locale/en/*.json', { eager: true }),
      ...import.meta.glob('../../i18n/locale/pt_BR/*.json', { eager: true }),
    };
    // Junção profunda: um mesmo grupo de textos pode estar em mais de um arquivo.
    const chatwoot = Object.entries(files)
      .filter(([file]) => !file.endsWith('chatcleanVocabulary.json'))
      .reduce(
        (merged, [, module]) => withVocabulary(merged, module.default),
        {}
      );
    const missing = texts(chatcleanVocabulary)
      .map(([key]) => key.replace(/\.\d+(\..*)?$/, ''))
      .filter(
        key =>
          key.split('.').reduce((node, part) => node?.[part], chatwoot) ===
          undefined
      );

    expect(missing).toEqual([]);
  });

  it('applies the rewritten texts over the Chatwoot ones', () => {
    expect(ptBR.SIDEBAR.CONVERSATIONS).toBe('Atendimentos');
    expect(ptBR.SIDEBAR.INBOXES).toBe('Canais');
    expect(ptBR.SIDEBAR.TEAMS).toBe('Departamentos');
    expect(ptBR.SIDEBAR.CAMPAIGNS).toBe('Envios');
    expect(ptBR.SIDEBAR.REPORTS).toBe('Dashboards');
  });

  it('merges nested texts without dropping the others', () => {
    const merged = withVocabulary(
      { A: { B: 'conversa', C: 'mantém' }, D: ['x', 'y'] },
      { A: { B: 'atendimento' }, D: ['z', 'y'] }
    );

    expect(merged).toEqual({
      A: { B: 'atendimento', C: 'mantém' },
      D: ['z', 'y'],
    });
  });
});
