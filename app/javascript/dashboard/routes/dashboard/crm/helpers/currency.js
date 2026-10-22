// Todo deal do CRM é em reais (currency BRL).
const brl = new Intl.NumberFormat('pt-BR', {
  style: 'currency',
  currency: 'BRL',
});

export const formatCurrency = value => brl.format(Number(value) || 0);
