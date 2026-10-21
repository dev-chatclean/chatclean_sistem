require 'rails_helper'

RSpec.describe Crm::Stage do
  let(:stage) { create(:crm_stage) }

  it 'uses the crm_stages table' do
    expect(described_class.table_name).to eq('crm_stages')
  end

  context 'with validations' do
    subject { build(:crm_stage) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_numericality_of(:position).only_integer.is_greater_than_or_equal_to(0) }
    it { is_expected.to define_enum_for(:status).with_values(open: 0, won: 1, lost: 2) }

    it 'rejects a pipeline from another account' do
      expect(build(:crm_stage, account: create(:account))).not_to be_valid
    end
  end

  describe '#destroy' do
    it 'is blocked while the stage has deals' do
      create(:crm_deal, account: stage.account, stage: stage)

      expect(stage.destroy).to be(false)
      expect(stage.errors[:base]).to include(I18n.t('errors.crm.stage.has_deals'))
    end

    it 'removes a stage without deals' do
      expect(stage.destroy).to be_truthy
    end
  end
end
