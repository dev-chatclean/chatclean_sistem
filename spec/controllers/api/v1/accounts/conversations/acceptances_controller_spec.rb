require 'rails_helper'

RSpec.describe 'Conversation Acceptance API', type: :request do
  let(:account) { create(:account) }
  let(:conversation) { create(:conversation, account: account, assignee: nil) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:colleague) { create(:user, account: account, role: :agent, name: 'Bruno') }
  let(:path) { "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}/acceptance" }

  before do
    create(:inbox_member, inbox: conversation.inbox, user: agent)
    create(:inbox_member, inbox: conversation.inbox, user: colleague)
  end

  it 'returns unauthorized for unauthenticated users' do
    post path

    expect(response).to have_http_status(:unauthorized)
  end

  it 'makes the agent the assignee of a pending conversation' do
    post path, headers: agent.create_new_auth_token, as: :json

    expect(response).to have_http_status(:success)
    expect(response.parsed_body['id']).to eq(agent.id)
    expect(conversation.reload.assignee).to eq(agent)
  end

  it 'refuses a conversation already accepted by someone else (FA 15.1)' do
    conversation.update!(assignee: colleague)

    post path, headers: agent.create_new_auth_token, as: :json

    expect(response).to have_http_status(:conflict)
    expect(response.parsed_body['error']).to eq(I18n.t('chatclean.conversations.already_accepted', name: colleague.available_name))
    expect(conversation.reload.assignee).to eq(colleague)
  end

  it 'answers success again for the agent who already accepted it' do
    conversation.update!(assignee: agent)

    post path, headers: agent.create_new_auth_token, as: :json

    expect(response).to have_http_status(:success)
    expect(conversation.reload.assignee).to eq(agent)
  end

  it 'returns unauthorized for an agent without access to the inbox' do
    outsider = create(:user, account: account, role: :agent)

    post path, headers: outsider.create_new_auth_token, as: :json

    expect(response).to have_http_status(:unauthorized)
    expect(conversation.reload.assignee).to be_nil
  end
end
