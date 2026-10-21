require 'rails_helper'

RSpec.describe Crm::Stage do
  let(:pipeline) { create(:crm_pipeline) }
  let(:stage) { create(:crm_stage, pipeline: pipeline) }
  let(:won) { pipeline.stages.won.first }

  it 'uses the crm_stages table' do
    expect(described_class.table_name).to eq('crm_stages')
  end

  context 'with validations' do
    subject { build(:crm_stage) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_numericality_of(:position).only_integer.is_greater_than_or_equal_to(0) }
    it { is_expected.to define_enum_for(:status).with_values(open: 0, won: 1, lost: 2) }

    it 'accepts probabilities from 0 to 100 only' do
      expect(build(:crm_stage, pipeline: pipeline, probability: 60)).to be_valid
      expect(build(:crm_stage, pipeline: pipeline, probability: 101)).not_to be_valid
      expect(build(:crm_stage, pipeline: pipeline, probability: -1)).not_to be_valid
    end

    it 'rejects a pipeline from another account' do
      expect(build(:crm_stage, pipeline: pipeline, account: create(:account))).not_to be_valid
    end

    it 'allows only one won and one lost stage per pipeline' do
      extra = build(:crm_stage, pipeline: pipeline, status: :won)

      expect(extra).not_to be_valid
      expect(extra.errors[:status]).to include(I18n.t('errors.crm.stage.single_closing_stage'))
    end
  end

  describe 'won and lost stages' do
    it 'can be renamed' do
      expect(won.update(name: 'Fechado')).to be(true)
    end

    it 'keep their status and probability' do
      expect(won.update(probability: 80)).to be(false)
      expect(won.errors[:base]).to include(I18n.t('errors.crm.stage.closing_stage_immutable'))
      expect(won.reload.update(status: :open)).to be(false)
    end

    it 'cannot be deleted on their own' do
      expect(won.destroy).to be(false)
      expect(won.errors[:base]).to include(I18n.t('errors.crm.stage.closing_stage_undeletable'))
    end
  end

  describe '#destroy' do
    it 'is blocked while the stage has deals' do
      create(:crm_deal, account: pipeline.account, stage: stage)

      expect(stage.destroy).to be(false)
      expect(stage.errors[:base]).to include(I18n.t('errors.crm.stage.has_deals'))
    end

    it 'removes an open stage without deals' do
      expect(stage.destroy).to be_truthy
    end
  end
end
