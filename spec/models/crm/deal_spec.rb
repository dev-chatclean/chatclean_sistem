require 'rails_helper'

RSpec.describe Crm::Deal do
  let(:account) { create(:account) }
  let(:pipeline) { create(:crm_pipeline, account: account) }
  let(:open_stage) { create(:crm_stage, pipeline: pipeline) }

  it 'uses the crm_deals table' do
    expect(described_class.table_name).to eq('crm_deals')
  end

  context 'with validations' do
    subject { build(:crm_deal) }

    it { is_expected.to validate_presence_of(:title) }
    it { is_expected.to validate_numericality_of(:value).is_greater_than_or_equal_to(0) }
    it { is_expected.to belong_to(:crm_contact).required }
    it { is_expected.to belong_to(:stage).required }
    it { is_expected.to belong_to(:assignee).optional }

    it 'stores money with two decimal places' do
      deal = create(:crm_deal, value: 1234.567)

      expect(deal.reload.value).to eq(BigDecimal('1234.57'))
    end

    it 'rejects negative values in the database' do
      deal = create(:crm_deal)
      deal.value = -1

      expect { deal.save!(validate: false) }.to raise_error(ActiveRecord::StatementInvalid, /crm_deals_value_non_negative/)
    end

    it 'rejects a stage from another account' do
      expect(build(:crm_deal, account: account, stage: create(:crm_stage))).not_to be_valid
    end

    it 'rejects a CRM contact from another account' do
      expect(build(:crm_deal, account: account, stage: open_stage, crm_contact: create(:crm_contact))).not_to be_valid
    end

    it 'accepts only agents of the same account as assignee' do
      agent = create(:user, account: account)

      expect(build(:crm_deal, account: account, stage: open_stage, assignee: agent)).to be_valid
      expect(build(:crm_deal, account: account, stage: open_stage, assignee: create(:user))).not_to be_valid
    end
  end

  describe 'status driven by the stage' do
    let(:deal) { create(:crm_deal, account: account, stage: open_stage) }

    it 'starts with the status of its stage' do
      expect(deal).to be_open
    end

    it 'follows the stage when moved' do
      deal.update!(stage: create(:crm_stage, :won, pipeline: pipeline))
      expect(deal).to be_won

      deal.update!(stage: create(:crm_stage, :lost, pipeline: pipeline))
      expect(deal).to be_lost

      deal.update!(stage: open_stage)
      expect(deal).to be_open
    end
  end

  it 'exposes the pipeline through the stage' do
    expect(create(:crm_deal, account: account, stage: open_stage).pipeline).to eq(pipeline)
  end

  it 'removes all CRM records when the account is deleted' do
    create(:crm_deal, account: account, stage: open_stage)

    Account.where(id: account.id).delete_all

    expect([Crm::Pipeline, Crm::Stage, Crm::Contact, described_class].map { |model| model.where(account_id: account.id).count })
      .to all(eq(0))
  end
end
