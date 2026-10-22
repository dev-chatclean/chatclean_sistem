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
      deal.update!(stage: pipeline.stages.won.first)
      expect(deal).to be_won

      deal.update!(stage: pipeline.stages.lost.first, loss_reason: create(:crm_loss_reason, account: account))
      expect(deal).to be_lost

      deal.update!(stage: open_stage)
      expect(deal).to be_open
    end
  end

  describe 'losing and winning' do
    let(:deal) { create(:crm_deal, account: account, stage: open_stage) }
    let(:lost_stage) { pipeline.stages.lost.first }
    let(:won_stage) { pipeline.stages.won.first }
    let(:loss_reason) { create(:crm_loss_reason, account: account) }

    it 'requires a loss reason to lose the deal' do
      expect(deal.update(stage: lost_stage)).to be(false)
      expect(deal.errors[:loss_reason]).to include(I18n.t('errors.crm.deal.loss_reason_required'))
    end

    it 'records the loss reason and details' do
      deal.update!(stage: lost_stage, loss_reason: loss_reason, loss_details: 'Concorrente 20% mais barato')

      expect(deal.reload).to have_attributes(status: 'lost', loss_reason: loss_reason, loss_details: 'Concorrente 20% mais barato')
    end

    it 'rejects an inactive loss reason' do
      expect(deal.update(stage: lost_stage, loss_reason: create(:crm_loss_reason, :inactive, account: account))).to be(false)
      expect(deal.errors[:loss_reason]).to include(I18n.t('errors.crm.deal.inactive_loss_reason'))
    end

    it 'rejects a loss reason from another account' do
      expect(deal.update(stage: lost_stage, loss_reason: create(:crm_loss_reason))).to be(false)
    end

    it 'does not require anything to win' do
      expect(deal.update(stage: won_stage)).to be(true)
      expect(deal).to be_won
    end

    it 'clears the loss data when a lost deal is won or reopened' do
      deal.update!(stage: lost_stage, loss_reason: loss_reason, loss_details: 'Sem orçamento')

      deal.update!(stage: open_stage)

      expect(deal.reload).to have_attributes(status: 'open', loss_reason: nil, loss_details: nil)
    end

    it 'keeps the status history, including reopenings' do
      deal.update!(stage: lost_stage, loss_reason: loss_reason)
      deal.update!(stage: open_stage)

      # Na criação o audited grava só o valor; nas mudanças, o par [antes, depois].
      statuses = deal.audits.filter_map { |audit| audit.audited_changes['status'] }.map { |change| Array(change).last }

      expect(statuses).to eq([0, 2, 0])
    end
  end

  describe 'origin conversation' do
    let(:contact) { create(:contact, account: account) }
    let(:crm_contact) { create(:crm_contact, contact: contact) }
    let(:conversation) { create(:conversation, account: account, contact: contact) }
    let(:deal) { create(:crm_deal, account: account, stage: open_stage, crm_contact: crm_contact, conversation: conversation) }

    it 'links a conversation of the deal contact' do
      expect(deal.reload.conversation).to eq(conversation)
    end

    it 'rejects a conversation of another contact' do
      other = create(:conversation, account: account)
      record = build(:crm_deal, account: account, stage: open_stage, crm_contact: crm_contact, conversation: other)

      expect(record).not_to be_valid
      expect(record.errors[:conversation_id]).to include(I18n.t('errors.crm.deal.conversation_other_contact'))
    end

    it 'rejects a conversation of another account' do
      record = build(:crm_deal, account: account, stage: open_stage, crm_contact: crm_contact, conversation: create(:conversation))

      expect(record).not_to be_valid
      expect(record.errors[:conversation_id]).to be_present
    end

    it 'validates without raising when the deal has no CRM contact' do
      record = build(:crm_deal, account: account, stage: open_stage, crm_contact: nil, conversation: conversation)

      expect(record).not_to be_valid
      expect(record.errors[:crm_contact]).to be_present
    end

    it 'can be set later when the deal has no origin yet' do
      without_origin = create(:crm_deal, account: account, stage: open_stage, crm_contact: crm_contact)

      expect(without_origin.update(conversation: conversation)).to be(true)
    end

    it 'cannot be replaced or removed once set' do
      other = create(:conversation, account: account, contact: contact)

      expect(deal.update(conversation: other)).to be(false)
      expect(deal.errors[:conversation_id]).to include(I18n.t('errors.crm.deal.conversation_readonly'))
      expect(deal.reload.update(conversation: nil)).to be(false)
    end

    it 'keeps the deal without origin when the conversation is deleted' do
      deal

      conversation.destroy!

      expect(deal.reload.conversation_id).to be_nil
    end

    it 'records the origin in the history' do
      expect(deal.audits.first.audited_changes['conversation_id']).to eq(conversation.id)
    end
  end

  it 'allows many deals for the same contact, in the same or different pipelines' do
    crm_contact = create(:crm_contact, contact: create(:contact, account: account))
    other_stage = create(:crm_stage, pipeline: create(:crm_pipeline, account: account))

    create_list(:crm_deal, 2, account: account, stage: open_stage, crm_contact: crm_contact)
    create(:crm_deal, account: account, stage: other_stage, crm_contact: crm_contact)

    expect(crm_contact.deals.count).to eq(3)
  end

  it 'keeps a deal of a blocked contact lost until the contact is unblocked' do
    contact = create(:contact, account: account)
    deal = create(:crm_deal, account: account, stage: pipeline.stages.lost.first,
                             crm_contact: create(:crm_contact, contact: contact), loss_reason: create(:crm_loss_reason, account: account))
    contact.update!(blocked: true)

    expect(deal.reload.update(stage: open_stage)).to be(false)
    expect(deal.errors[:crm_contact]).to include(I18n.t('errors.crm.deal.blocked_contact_locked'))

    contact.update!(blocked: false)
    expect(deal.reload.update(stage: open_stage)).to be(true)
  end

  it 'keeps the assignee of a blocked contact deal' do
    contact = create(:contact, account: account)
    deal = create(:crm_deal, account: account, stage: open_stage, crm_contact: create(:crm_contact, contact: contact))
    contact.update!(blocked: true)

    expect(deal.reload.update(assignee: create(:user, account: account))).to be(false)
    expect(deal.errors[:crm_contact]).to include(I18n.t('errors.crm.deal.blocked_contact_assignee_locked'))
  end

  it 'filters by assignee, including unassigned deals' do
    agent = create(:user, account: account)
    assigned = create(:crm_deal, account: account, stage: open_stage, assignee: agent)
    unassigned = create(:crm_deal, account: account, stage: open_stage)

    expect(described_class.assigned_to(agent.id.to_s)).to eq([assigned])
    expect(described_class.assigned_to('none')).to eq([unassigned])
  end

  it 'only accepts BRL' do
    expect(build(:crm_deal, currency: 'USD')).not_to be_valid
  end

  it 'does not open deals for a blocked contact' do
    blocked = create(:crm_contact, contact: create(:contact, account: account, blocked: true))

    expect(build(:crm_deal, account: account, stage: open_stage, crm_contact: blocked)).not_to be_valid
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
