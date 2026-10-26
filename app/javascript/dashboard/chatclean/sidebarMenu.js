// Menu lateral na organização da ChatClean atual (US 14, CCV2-29). Recebe os itens que o
// Sidebar.vue do Chatwoot monta e devolve:
// - sem a caixa de entrada de notificações, que fica no sino da barra superior;
// - Empresas dentro de Contatos;
// - Canais no menu principal, fora de Configurações;
// - sem Automação, Macros e envios por SMS;
// - na ordem da ChatClean. Item novo de uma atualização do Chatwoot entra no fim, antes de
//   Configurações.

const MENU_ORDER = [
  'Reports',
  'Conversation',
  'Contacts',
  'CRM',
  'Campaigns',
  'Channels',
  'Portals',
  'Calls',
  'Settings',
];

const HIDDEN_SETTINGS = [
  'Settings Automation',
  'Settings Macros',
  'Settings Inboxes',
];

const withoutChildren = (item, names) => ({
  ...item,
  children: item.children.filter(child => !names.includes(child.name)),
});

export const chatcleanMenu = items => {
  const byName = Object.fromEntries(items.map(item => [item.name, item]));
  const { Companies: companies, Settings: settings } = byName;

  const menu = items
    .filter(item => !['Inbox', 'Companies'].includes(item.name))
    .map(item => {
      if (item.name === 'Contacts' && companies) {
        const [allCompanies] = companies.children;
        return {
          ...item,
          children: [
            ...item.children,
            { ...allCompanies, label: companies.label, icon: companies.icon },
          ],
        };
      }
      if (item.name === 'Campaigns') return withoutChildren(item, ['SMS']);
      if (item.name === 'Settings') {
        return withoutChildren(item, HIDDEN_SETTINGS);
      }
      return item;
    });

  const channels = settings?.children.find(
    child => child.name === 'Settings Inboxes'
  );
  if (channels) menu.push({ ...channels, name: 'Channels' });

  // Itens desconhecidos ficam logo antes de Configurações, na ordem em que vieram.
  const beforeSettings = MENU_ORDER.indexOf('Settings') - 0.5;
  const position = item => {
    const index = MENU_ORDER.indexOf(item.name);
    return index === -1 ? beforeSettings : index;
  };
  return menu
    .map((item, index) => ({ item, index }))
    .sort((a, b) => position(a.item) - position(b.item) || a.index - b.index)
    .map(({ item }) => item);
};
