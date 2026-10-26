import { withAgentName } from '../conversation/agentSignature';

const user = { name: 'Maria Souza', display_name: 'Maria' };

describe('withAgentName', () => {
  it('puts the display name in bold on the first line', () => {
    expect(
      withAgentName('Bom dia', { user, channelType: 'Channel::WebWidget' })
    ).toBe('**Maria:**  \nBom dia');
  });

  it('falls back to the full name without a display name', () => {
    expect(
      withAgentName('Bom dia', {
        user: { name: 'Maria Souza', display_name: '' },
        channelType: 'Channel::Whatsapp',
      })
    ).toBe('**Maria Souza:**  \nBom dia');
  });

  it('leaves the name without bold where the channel would show the asterisks', () => {
    ['Channel::Instagram', 'Channel::FacebookPage', 'Channel::Tiktok'].forEach(
      channelType => {
        expect(withAgentName('Oi', { user, channelType })).toBe('Maria:  \nOi');
      }
    );
  });

  it('does not sign a message without text', () => {
    expect(
      withAgentName('  ', { user, channelType: 'Channel::WebWidget' })
    ).toBe('  ');
  });
});
