require 'rails_helper'

RSpec.describe 'Canned responses by team and user', type: :request do
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:other_agent) { create(:user, account: account, role: :agent) }
  let(:sales) { create(:team, account: account) }
  let(:path) { "/api/v1/accounts/#{account.id}/canned_responses" }
  let(:pdf) { fixture_file_upload(Rails.root.join('spec/assets/sample.pdf'), 'application/pdf') }

  def short_codes(user, params = {})
    get path, params: params, headers: user.create_new_auth_token, as: :json
    response.parsed_body.pluck('short_code')
  end

  before do
    create(:team_member, team: sales, user: agent)
    create(:canned_response, account: account, short_code: 'todos')
    create(:canned_response, account: account, short_code: 'vendas', visibility: :teams, teams: [sales])
    create(:canned_response, account: account, short_code: 'suporte', visibility: :teams, teams: [create(:team, account: account)])
    create(:canned_response, account: account, short_code: 'minha', visibility: :personal, owner: agent)
    create(:canned_response, account: account, short_code: 'dele', visibility: :personal, owner: other_agent)
  end

  it 'shows an agent the shared ones, the ones of their teams and their own' do
    expect(short_codes(agent)).to contain_exactly('todos', 'vendas', 'minha')
  end

  it 'shows an administrator every shared one and only asks for the personal ones of others' do
    expect(short_codes(admin)).to contain_exactly('todos', 'vendas', 'suporte')
    expect(short_codes(admin, include_personal: true)).to contain_exactly('todos', 'vendas', 'suporte', 'minha', 'dele')
  end

  it 'stops showing the team ones as soon as the agent leaves the team' do
    TeamMember.find_by(team: sales, user: agent).destroy!

    expect(short_codes(agent)).to contain_exactly('todos', 'minha')
  end

  it 'makes what an agent creates personal, even when asking to share it' do
    post path, params: { canned_response: { short_code: 'oi', content: 'Oi!', visibility: 'everyone' } },
               headers: agent.create_new_auth_token, as: :json

    expect(response).to have_http_status(:success)
    expect(CannedResponse.find_by(short_code: 'oi')).to have_attributes(visibility: 'personal', owner: agent)
  end

  it 'lets an administrator share with teams, without an owner' do
    post path, params: { canned_response: { short_code: 'tabela', content: 'Segue a tabela', visibility: 'teams', team_ids: [sales.id] } },
               headers: admin.create_new_auth_token, as: :json

    expect(response.parsed_body).to include('visibility' => 'teams', 'team_ids' => [sales.id], 'owner_id' => nil)
  end

  it 'keeps the short code unique among the shared ones and among the ones of each user' do
    post path, params: { canned_response: { short_code: 'todos', content: 'x', visibility: 'everyone' } },
               headers: admin.create_new_auth_token, as: :json
    expect(response).to have_http_status(:unprocessable_entity)

    post path, params: { canned_response: { short_code: 'todos', content: 'x' } }, headers: agent.create_new_auth_token, as: :json
    expect(response).to have_http_status(:success)
  end

  it 'lets an agent change only their own and an administrator change any, keeping the owner' do
    shared = CannedResponse.find_by(short_code: 'todos')
    others = CannedResponse.find_by(short_code: 'dele')

    put "#{path}/#{shared.id}", params: { canned_response: { content: 'novo' } }, headers: agent.create_new_auth_token, as: :json
    expect(response).to have_http_status(:unauthorized)
    delete "#{path}/#{others.id}", headers: agent.create_new_auth_token, as: :json
    expect(response).to have_http_status(:unauthorized)

    put "#{path}/#{others.id}", params: { canned_response: { content: 'ajustado' } }, headers: admin.create_new_auth_token, as: :json
    expect(others.reload).to have_attributes(content: 'ajustado', owner: other_agent)
  end

  it 'adds, keeps and removes attachments' do
    post path, params: { canned_response: { short_code: 'pdf', content: 'Segue', attachments: [pdf] } }, headers: agent.create_new_auth_token
    created = response.parsed_body
    expect(created['attachments'].first).to include('file_name' => 'sample.pdf', 'content_type' => 'application/pdf')

    put "#{path}/#{created['id']}", params: { canned_response: { attachments: [pdf] } }, headers: agent.create_new_auth_token
    expect(response.parsed_body['attachments'].size).to eq(2)

    put "#{path}/#{created['id']}", params: { canned_response: { remove_attachment_ids: [created['attachments'].first['id']] } },
                                    headers: agent.create_new_auth_token
    expect(response.parsed_body['attachments'].size).to eq(1)
  end

  it 'refuses attachments above 16 MB in total' do
    stub_const('Chatclean::CannedResponseScope::MAX_ATTACHMENTS_SIZE', 10)

    post path, params: { canned_response: { short_code: 'grande', content: 'x', attachments: [pdf] } }, headers: agent.create_new_auth_token

    expect(response).to have_http_status(:unprocessable_entity)
    expect(CannedResponse.find_by(short_code: 'grande')).to be_nil
  end
end
