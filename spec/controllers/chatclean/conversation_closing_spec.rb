require 'rails_helper'

RSpec.describe 'Conversation closing with a reason', type: :request do
  let(:account) { create(:account) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:conversation) { create(:conversation, account: account, assignee: agent) }
  let(:reason) { create(:chatclean_closing_reason, account: account) }
  let(:path) { "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}/toggle_status" }

  before { create(:inbox_member, inbox: conversation.inbox, user: agent) }

  it 'refuses closing without a reason and keeps the conversation open' do
    post path, params: { status: 'resolved' }, headers: agent.create_new_auth_token, as: :json

    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.parsed_body['error']).to eq(I18n.t('chatclean.closing.reason_required'))
    expect(conversation.reload).to be_open
  end

  it 'refuses the toggle without status, which would close an open conversation' do
    post path, headers: agent.create_new_auth_token, as: :json

    expect(response).to have_http_status(:unprocessable_entity)
    expect(conversation.reload).to be_open
  end

  it 'closes with a reason and records the closing' do
    post path, params: { status: 'resolved', closing_reason_id: reason.id }, headers: agent.create_new_auth_token, as: :json

    expect(response).to have_http_status(:success)
    expect(response.parsed_body.dig('payload', 'current_status')).to eq('resolved')
    expect(Chatclean::ConversationClosure.last).to have_attributes(conversation: conversation, closing_reason: reason, user: agent)
  end

  it 'reopens and snoozes without a reason' do
    conversation.update!(status: :resolved)
    post path, params: { status: 'open' }, headers: agent.create_new_auth_token, as: :json
    expect(conversation.reload).to be_open

    post path, params: { status: 'pending' }, headers: agent.create_new_auth_token, as: :json
    expect(conversation.reload).to be_pending
  end

  it 'lets a bot close without a reason' do
    bot = create(:agent_bot, account: account)
    create(:agent_bot_inbox, inbox: conversation.inbox, agent_bot: bot)

    post path, params: { status: 'resolved' }, headers: { api_access_token: bot.access_token.token }, as: :json

    expect(response).to have_http_status(:success)
    expect(conversation.reload).to be_resolved
    expect(Chatclean::ConversationClosure.count).to eq(0)
  end

  describe 'bulk closing' do
    let(:bulk_path) { "/api/v1/accounts/#{account.id}/bulk_actions" }
    let(:other) { create(:conversation, account: account, inbox: conversation.inbox, assignee: agent) }

    it 'refuses the bulk close without a reason' do
      expect do
        post bulk_path, params: { type: 'Conversation', ids: [conversation.display_id], fields: { status: 'resolved' } },
                        headers: agent.create_new_auth_token, as: :json
      end.not_to have_enqueued_job(BulkActionsJob)

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'closes every conversation with the same reason and sale value' do
      sale_reason = create(:chatclean_closing_reason, :sale, account: account)

      perform_enqueued_jobs(only: BulkActionsJob) do
        post bulk_path, params: { type: 'Conversation', ids: [conversation.display_id, other.display_id], fields: { status: 'resolved' },
                                  closing_reason_id: sale_reason.id, sale_value: '99.9' },
                        headers: agent.create_new_auth_token, as: :json
      end

      expect(response).to have_http_status(:success)
      expect([conversation.reload, other.reload]).to all(be_resolved)
      expect(Chatclean::ConversationClosure.pluck(:conversation_id, :sale_value))
        .to contain_exactly([conversation.id, 99.9], [other.id, 99.9])
    end
  end
end
