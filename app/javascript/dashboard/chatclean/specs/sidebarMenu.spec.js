import { chatcleanMenu } from '../sidebarMenu';

const chatwootMenu = () => [
  { name: 'Inbox', label: 'Caixa de entrada' },
  { name: 'Conversation', label: 'Atendimentos', children: [] },
  { name: 'Captain', label: 'Captain', children: [] },
  {
    name: 'Contacts',
    label: 'Contatos',
    children: [{ name: 'All Contacts', label: 'Todos' }],
  },
  {
    name: 'Companies',
    label: 'Empresas',
    icon: 'i-lucide-building-2',
    children: [{ name: 'All Companies', label: 'Todas', to: '/companies' }],
  },
  { name: 'CRM', label: 'Pipeline' },
  { name: 'Reports', label: 'Dashboards', children: [] },
  {
    name: 'Campaigns',
    label: 'Envios',
    children: [
      { name: 'Live chat', label: 'Chat ao vivo' },
      { name: 'SMS', label: 'SMS' },
      { name: 'WhatsApp', label: 'WhatsApp' },
    ],
  },
  { name: 'Portals', label: 'Central de ajuda', children: [] },
  {
    name: 'Settings',
    label: 'Configurações',
    children: [
      { name: 'Settings Account Settings', label: 'Conta' },
      { name: 'Settings Inboxes', label: 'Canais', to: '/inboxes' },
      { name: 'Settings Automation', label: 'Automação' },
      { name: 'Settings Macros', label: 'Macros' },
      { name: 'Settings Labels', label: 'Etiquetas' },
    ],
  },
];

describe('chatcleanMenu', () => {
  it('puts the items in the order of the current ChatClean', () => {
    expect(chatcleanMenu(chatwootMenu()).map(item => item.name)).toEqual([
      'Reports',
      'Conversation',
      'Contacts',
      'CRM',
      'Campaigns',
      'Channels',
      'Portals',
      'Captain',
      'Settings',
    ]);
  });

  it('moves the notifications inbox out of the menu', () => {
    const names = chatcleanMenu(chatwootMenu()).map(item => item.name);

    expect(names).not.toContain('Inbox');
  });

  it('nests the companies inside the contacts', () => {
    const contacts = chatcleanMenu(chatwootMenu()).find(
      item => item.name === 'Contacts'
    );

    expect(contacts.children.at(-1)).toMatchObject({
      name: 'All Companies',
      label: 'Empresas',
      icon: 'i-lucide-building-2',
      to: '/companies',
    });
  });

  it('turns the inboxes settings into the Channels menu item', () => {
    const menu = chatcleanMenu(chatwootMenu());
    const settings = menu.find(item => item.name === 'Settings');

    expect(menu.find(item => item.name === 'Channels')).toMatchObject({
      label: 'Canais',
      to: '/inboxes',
    });
    expect(settings.children.map(child => child.name)).toEqual([
      'Settings Account Settings',
      'Settings Labels',
    ]);
  });

  it('hides the SMS campaigns', () => {
    const campaigns = chatcleanMenu(chatwootMenu()).find(
      item => item.name === 'Campaigns'
    );

    expect(campaigns.children.map(child => child.name)).toEqual([
      'Live chat',
      'WhatsApp',
    ]);
  });

  it('keeps an unknown item from a Chatwoot update before the settings', () => {
    const menu = chatcleanMenu([...chatwootMenu(), { name: 'Novidade' }]);

    expect(menu.map(item => item.name).slice(-2)).toEqual([
      'Novidade',
      'Settings',
    ]);
  });
});
