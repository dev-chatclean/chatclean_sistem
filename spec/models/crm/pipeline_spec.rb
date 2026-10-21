require 'rails_helper'

RSpec.describe Crm::Pipeline do
  let(:account) { create(:account) }

  it 'uses the crm_pipelines table' do
    expect(described_class.table_name).to eq('crm_pipelines')
  end

  context 'with validations' do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to belong_to(:account) }

    it 'allows only one default pipeline per account' do
      create(:crm_pipeline, account: account, is_default: true)

      expect(build(:crm_pipeline, account: account, is_default: true)).not_to be_valid
      expect(build(:crm_pipeline, is_default: true)).to be_valid
    end
  end

  it 'lists stages by position' do
    pipeline = create(:crm_pipeline, account: account)
    last = create(:crm_stage, pipeline: pipeline, position: 2)
    first = create(:crm_stage, pipeline: pipeline, position: 0)

    expect(pipeline.stages).to eq([first, last])
  end

  describe '#destroy' do
    let(:pipeline) { create(:crm_pipeline, account: account) }
    let!(:stage) { create(:crm_stage, pipeline: pipeline) }

    it 'removes the pipeline and its stages when there are no deals' do
      expect(pipeline.destroy).to be_truthy
      expect(Crm::Stage.exists?(stage.id)).to be(false)
    end

    it 'is blocked while the pipeline has deals' do
      create(:crm_deal, account: account, stage: stage)

      expect(pipeline.destroy).to be(false)
      expect(pipeline.errors[:base]).to include(I18n.t('errors.crm.pipeline.has_deals'))
      expect(described_class.exists?(pipeline.id)).to be(true)
    end
  end
end
