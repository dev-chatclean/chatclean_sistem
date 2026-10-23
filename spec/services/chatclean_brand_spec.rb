require 'rails_helper'

describe ChatcleanBrand do
  it 'uses the configured brand' do
    create(:installation_config, name: 'INSTALLATION_NAME', value: 'ChatClean')

    expect(described_class.value('INSTALLATION_NAME')).to eq('ChatClean')
  end

  it 'falls back to the bundled assets when the brand is not configured' do
    expect(described_class.value('LOGO_THUMBNAIL')).to eq('/brand-assets/logo_thumbnail.svg')
  end
end
