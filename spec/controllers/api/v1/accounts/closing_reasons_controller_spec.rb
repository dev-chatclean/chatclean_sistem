require 'rails_helper'

RSpec.describe 'Closing Reasons API', type: :request do
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:team) { create(:team, account: account) }
  let(:path) { "/api/v1/accounts/#{account.id}/closing_reasons" }

  it 'lets an administrator create a reason with message, sale value and teams' do
    post path, params: { closing_reason: { name: 'Venda', closing_message: 'Obrigado!', ask_sale_value: true, team_ids: [team.id] } },
               headers: admin.create_new_auth_token, as: :json

    expect(response).to have_http_status(:success)
    expect(response.parsed_body['payload']).to include('name' => 'Venda', 'closing_message' => 'Obrigado!', 'ask_sale_value' => true,
                                                       'is_active' => true, 'team_ids' => [team.id])
  end

  it 'refuses a repeated name' do
    create(:chatclean_closing_reason, account: account, name: 'Venda')

    post path, params: { closing_reason: { name: 'venda' } }, headers: admin.create_new_auth_token, as: :json

    expect(response).to have_http_status(:unprocessable_entity)
  end

  it 'does not let an agent manage reasons' do
    reason = create(:chatclean_closing_reason, account: account)

    post path, params: { closing_reason: { name: 'Outro' } }, headers: agent.create_new_auth_token, as: :json
    expect(response).to have_http_status(:unauthorized)

    delete "#{path}/#{reason.id}", headers: agent.create_new_auth_token, as: :json
    expect(response).to have_http_status(:unauthorized)
  end

  it 'lists to an agent only the active reasons they can use' do
    general = create(:chatclean_closing_reason, account: account)
    create(:chatclean_closing_reason, account: account, is_active: false)
    create(:chatclean_closing_reason, account: account, teams: [team])

    get path, params: { active: true }, headers: agent.create_new_auth_token, as: :json

    expect(response.parsed_body['payload'].pluck('id')).to eq([general.id])
  end

  it 'deletes an unused reason and only lets a used one be deactivated' do
    unused = create(:chatclean_closing_reason, account: account)
    used = create(:chatclean_closing_reason, account: account)
    conversation = create(:conversation, account: account)
    Chatclean::ConversationClosure.create!(account: account, conversation: conversation, closing_reason: used, user: admin)

    delete "#{path}/#{unused.id}", headers: admin.create_new_auth_token, as: :json
    expect(response).to have_http_status(:success)

    delete "#{path}/#{used.id}", headers: admin.create_new_auth_token, as: :json
    expect(response).to have_http_status(:unprocessable_entity)

    patch "#{path}/#{used.id}", params: { closing_reason: { is_active: false } }, headers: admin.create_new_auth_token, as: :json
    expect(used.reload.is_active).to be(false)
  end
end
