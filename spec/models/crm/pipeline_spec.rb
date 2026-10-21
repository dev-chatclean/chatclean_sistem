require 'rails_helper'

RSpec.describe Crm::Pipeline do
  let(:account) { create(:account) }

  it 'uses the crm_pipelines table' do
    expect(described_class.table_name).to eq('crm_pipelines')
  end

  context 'with validations' do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to belong_to(:account) }
  end

  describe 'closing stages' do
    let(:pipeline) { create(:crm_pipeline, account: account) }

    it 'creates the won and lost stages with the pipeline' do
      expect(pipeline.stages.map { |stage| [stage.name, stage.status, stage.probability] })
        .to eq([['Won', 'won', 100], ['Lost', 'lost', 0]])
    end

    it 'names them in the current locale' do
      stages = I18n.with_locale(:pt_BR) { create(:crm_pipeline, account: account).stages }

      expect(stages.map(&:name)).to eq(%w[Ganho Perdido])
    end

    it 'keeps open stages before won and lost, in creation order' do
      first = create(:crm_stage, pipeline: pipeline)
      second = create(:crm_stage, pipeline: pipeline)

      expect(pipeline.stages.reload.map(&:id)).to eq([first.id, second.id, *pipeline.stages.where.not(status: :open).ids])
    end
  end

  describe 'default pipeline' do
    it 'moves the default flag to the newly marked pipeline' do
      previous = create(:crm_pipeline, account: account, is_default: true)
      current = create(:crm_pipeline, account: account, is_default: true)

      expect(previous.reload.is_default).to be(false)
      expect(current.reload.is_default).to be(true)
    end

    it 'does not touch the default of other accounts' do
      other = create(:crm_pipeline, is_default: true)
      create(:crm_pipeline, account: account, is_default: true)

      expect(other.reload.is_default).to be(true)
    end
  end

  describe '#reorder_open_stages!' do
    let(:pipeline) { create(:crm_pipeline, account: account) }
    let!(:first) { create(:crm_stage, pipeline: pipeline) }
    let!(:second) { create(:crm_stage, pipeline: pipeline) }

    it 'reorders the open stages and keeps won and lost at the end' do
      pipeline.reorder_open_stages!([second.id, first.id])

      expect(pipeline.stages.map(&:id).first(2)).to eq([second.id, first.id])
      expect(pipeline.stages.last(2).map(&:status)).to eq(%w[won lost])
    end

    it 'rejects a list that misses or adds stages and changes nothing' do
      [[first.id], [first.id, second.id, pipeline.stages.won.first.id], [first.id, first.id]].each do |ids|
        expect { pipeline.reorder_open_stages!(ids) }.to raise_error(ActiveRecord::RecordInvalid)
      end
      expect(pipeline.stages.reload.first(2)).to eq([first, second])
    end
  end

  describe '#destroy' do
    let(:pipeline) { create(:crm_pipeline, account: account) }

    before { create(:crm_stage, pipeline: pipeline) }

    it 'removes the pipeline and all its stages, including won and lost, when there are no deals' do
      expect(pipeline.destroy).to be_truthy
      expect(Crm::Stage.where(crm_pipeline_id: pipeline.id)).to be_empty
    end

    it 'is blocked while the pipeline has deals, in any status' do
      create(:crm_deal, account: account, stage: pipeline.stages.won.first)

      expect(pipeline.destroy).to be(false)
      expect(pipeline.errors[:base]).to include(I18n.t('errors.crm.pipeline.has_deals'))
      expect(described_class.exists?(pipeline.id)).to be(true)
    end
  end
end
