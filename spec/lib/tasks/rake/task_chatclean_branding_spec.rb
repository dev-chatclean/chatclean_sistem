require 'rake'
require 'rails_helper'

RSpec.describe Rake::Task do
  subject(:task) { described_class['chatclean:branding'] }

  before { task.reenable }

  it 'replaces the Chatwoot branding with ChatClean, idempotently' do
    InstallationConfig.find_or_initialize_by(name: 'INSTALLATION_NAME').update!(value: 'Chatwoot')

    2.times do
      task.reenable
      expect { task.invoke }.to output(/Marca ChatClean aplicada/).to_stdout
    end

    expect(GlobalConfig.get_value('INSTALLATION_NAME')).to eq('ChatClean')
    expect(GlobalConfig.get_value('LOGO_THUMBNAIL')).to eq('/brand-assets/chatclean/logo-thumbnail.png')
    expect(GlobalConfig.get_value('DISPLAY_MANIFEST')).to be(false)
    expect(InstallationConfig.where(name: 'INSTALLATION_NAME').count).to eq(1)
  end
end
