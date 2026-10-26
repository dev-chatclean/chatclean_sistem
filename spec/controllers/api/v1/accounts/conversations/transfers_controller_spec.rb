require 'rails_helper'

RSpec.describe 'Conversation Transfer API', type: :request do
  let(:account) { create(:account) }
  let(:agent) { create(:user, account: account, role: :agent, name: 'Ana') }
  let(:colleague) { create(:user, account: account, role: :agent) }
  let(:conversation) { create(:conversation, account: account, assignee: agent) }
  let(:team) { create(:team, account: account) }
  let(:path) { "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}/transfer" }

  before do
    create(:inbox_member, inbox: conversation.inbox, user: agent)
    create(:inbox_member, inbox: conversation.inbox, user: colleague)
  end

  it 'returns unauthorized for unauthenticated users' do
    post path, params: { assignee_id: colleague.id }

    expect(response).to have_http_status(:unauthorized)
  end

  it 'transfers to an agent and a team, leaving the note as a private message of who transferred' do
    post path, params: { team_id: team.id, assignee_id: colleague.id, note: ' Cliente quer falar de preço ' },
               headers: agent.create_new_auth_token, as: :json

    expect(response).to have_http_status(:success)
    conversation.reload
    expect(conversation.assignee).to eq(colleague)
    expect(conversation.team).to eq(team)
    note = conversation.messages.where(private: true).last
    expect(note).to have_attributes(content: 'Cliente quer falar de preço', sender: agent)
  end

  it 'leaves the conversation without agent when it goes only to a team' do
    post path, params: { team_id: team.id }, headers: agent.create_new_auth_token, as: :json

    expect(response).to have_http_status(:success)
    expect(conversation.reload).to have_attributes(team: team, assignee: nil)
    expect(conversation.messages.where(private: true)).to be_empty
  end

  it 'requires a team or an agent' do
    post path, params: { note: 'Sem destino' }, headers: agent.create_new_auth_token, as: :json

    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.parsed_body['error']).to eq(I18n.t('chatclean.conversations.transfer.target_required'))
    expect(conversation.reload.assignee).to eq(agent)
  end

  it 'refuses an agent without access to the inbox (FA 15.2)' do
    outsider = create(:user, account: account, role: :agent)

    post path, params: { assignee_id: outsider.id }, headers: agent.create_new_auth_token, as: :json

    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.parsed_body['error']).to eq(I18n.t('chatclean.conversations.transfer.no_inbox_access'))
    expect(conversation.reload.assignee).to eq(agent)
  end

  it 'returns not found for a team of another account' do
    post path, params: { team_id: create(:team).id }, headers: agent.create_new_auth_token, as: :json

    expect(response).to have_http_status(:not_found)
  end
end
