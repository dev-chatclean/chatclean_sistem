require 'rails_helper'

RSpec.describe Chatclean::ConversationCloser do
  let(:account) { create(:account) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:account_user) { account.account_users.find_by(user: agent) }
  let(:conversation) { create(:conversation, account: account, assignee: agent) }
  let(:reason) { create(:chatclean_closing_reason, account: account) }
  let(:sale_reason) { create(:chatclean_closing_reason, :sale, account: account) }

  def closer(reason_id, sale_value = nil)
    described_class.new(account_user: account_user, reason_id: reason_id, sale_value: sale_value)
  end

  it 'closes the conversation and records the reason and who closed it' do
    closure = closer(reason.id).perform(conversation)

    expect(conversation.reload).to be_resolved
    expect(closure).to have_attributes(conversation: conversation, closing_reason: reason, user: agent, sale_value: nil, crm_deal: nil)
  end

  it 'sends the closing message of the reason before closing' do
    reason.update!(closing_message: 'Obrigado pelo contato!')

    closer(reason.id).perform(conversation)

    message = conversation.messages.outgoing.last
    expect(message).to have_attributes(content: 'Obrigado pelo contato!', sender: agent)
    expect(message.created_at).to be <= conversation.reload.updated_at
  end

  it 'refuses a missing, inactive or other account reason and keeps the conversation open' do
    inactive = create(:chatclean_closing_reason, account: account, is_active: false)
    other_account = create(:chatclean_closing_reason)

    [nil, inactive.id, other_account.id].each do |reason_id|
      expect { closer(reason_id).perform(conversation) }.to raise_error(described_class::Error)
    end
    expect(conversation.reload).to be_open
    expect(Chatclean::ConversationClosure.count).to eq(0)
  end

  it 'offers an agent the general reasons and the ones of their teams; an administrator gets all' do
    own_team = create(:team, account: account)
    create(:team_member, team: own_team, user: agent)
    own = create(:chatclean_closing_reason, account: account, teams: [own_team])
    other = create(:chatclean_closing_reason, account: account, teams: [create(:team, account: account)])

    available = Chatclean::ClosingReason.available_to(account_user)
    expect(available).to contain_exactly(reason, own)

    account_user.update!(role: :administrator)
    expect(Chatclean::ClosingReason.available_to(account_user)).to contain_exactly(reason, own, other)
  end

  it 'requires a non negative sale value when the reason asks for it' do
    [nil, '', '-1', 'abc'].each do |value|
      expect { closer(sale_reason.id, value).perform(conversation) }.to raise_error(described_class::Error)
    end

    expect(closer(sale_reason.id, '0').perform(conversation).sale_value).to eq(0)
  end

  describe 'sale value in the CRM' do
    let(:pipeline) { create(:crm_pipeline, account: account, is_default: true) }
    let(:open_stage) { create(:crm_stage, pipeline: pipeline, account: account) }
    let(:crm_contact) { create(:crm_contact, contact: conversation.contact, account: account) }

    def deal(attributes = {})
      create(:crm_deal, { account: account, crm_contact: crm_contact, stage: open_stage }.merge(attributes))
    end

    it 'wins the deal born in this conversation with the sale value' do
      origin = deal(conversation: conversation)
      deal

      closure = closer(sale_reason.id, '1500.50').perform(conversation)

      expect(closure.crm_deal).to eq(origin)
      expect(origin.reload).to have_attributes(status: 'won', value: 1500.5)
    end

    it 'wins the only open deal of the contact' do
      single = deal

      expect(closer(sale_reason.id, '300').perform(conversation).crm_deal).to eq(single)
      expect(single.reload).to be_won
    end

    it 'creates a won deal in the default pipeline for who closed when no deal fits' do
      2.times { deal }

      closure = closer(sale_reason.id, '300').perform(conversation)

      expect(closure.crm_deal).to have_attributes(status: 'won', value: 300, assignee: agent, conversation: conversation,
                                                  pipeline: pipeline, title: "#{sale_reason.name} — conversation ##{conversation.display_id}")
    end

    it 'keeps only the record when the account has no default pipeline' do
      closure = closer(sale_reason.id, '300').perform(conversation)

      expect(closure).to have_attributes(sale_value: 300, crm_deal: nil)
      expect(Crm::Deal.count).to eq(0)
    end

    it 'does not touch the CRM for a reason without sale value' do
      origin = deal(conversation: conversation)

      closer(reason.id).perform(conversation)

      expect(origin.reload).to be_open
    end
  end
end
