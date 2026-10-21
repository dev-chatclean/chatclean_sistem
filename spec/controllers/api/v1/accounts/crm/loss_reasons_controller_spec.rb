require 'rails_helper'

RSpec.describe 'CRM Loss Reasons API', type: :request do
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:base_path) { "/api/v1/accounts/#{account.id}/crm/loss_reasons" }

  describe 'GET /api/v1/accounts/{account.id}/crm/loss_reasons' do
    it 'returns unauthorized for unauthenticated users' do
      get base_path

      expect(response).to have_http_status(:unauthorized)
    end

    it 'lists the reasons of the account alphabetically, for agents too' do
      create(:crm_loss_reason, account: account, name: 'sem retorno')
      create(:crm_loss_reason, :inactive, account: account, name: 'Concorrente')
      create(:crm_loss_reason, name: 'Outra conta')

      get base_path, headers: agent.create_new_auth_token, as: :json

      expect(response).to have_http_status(:success)
      expect(response.parsed_body['payload'].pluck('name')).to eq(['Concorrente', 'sem retorno'])
    end

    it 'filters active reasons' do
      create(:crm_loss_reason, account: account, name: 'Preço alto')
      create(:crm_loss_reason, :inactive, account: account, name: 'Concorrente')

      get base_path, params: { active: 'true' }, headers: agent.create_new_auth_token, as: :json

      expect(response.parsed_body['payload'].pluck('name')).to eq(['Preço alto'])
    end
  end

  describe 'POST /api/v1/accounts/{account.id}/crm/loss_reasons' do
    it 'creates an active reason for administrators' do
      post base_path, params: { loss_reason: { name: 'Preço alto', description: 'Acima do orçamento' } },
                      headers: admin.create_new_auth_token, as: :json

      expect(response).to have_http_status(:success)
      expect(response.parsed_body['payload']).to include('name' => 'Preço alto', 'description' => 'Acima do orçamento', 'is_active' => true)
    end

    it 'does not let agents create reasons' do
      post base_path, params: { loss_reason: { name: 'Preço alto' } }, headers: agent.create_new_auth_token, as: :json

      expect(response).to have_http_status(:unauthorized)
      expect(Crm::LossReason.count).to eq(0)
    end

    it 'rejects a duplicated name ignoring case' do
      create(:crm_loss_reason, account: account, name: 'preço alto')

      post base_path, params: { loss_reason: { name: 'Preço Alto' } }, headers: admin.create_new_auth_token, as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body['attributes']).to eq(['name'])
    end

    it 'rejects a reason without name' do
      post base_path, params: { loss_reason: { name: '' } }, headers: admin.create_new_auth_token, as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body['attributes']).to eq(['name'])
    end
  end

  describe 'PATCH /api/v1/accounts/{account.id}/crm/loss_reasons/{id}' do
    let(:loss_reason) { create(:crm_loss_reason, account: account) }

    it 'lets administrators rename and deactivate a reason' do
      patch "#{base_path}/#{loss_reason.id}", params: { loss_reason: { name: 'Sem orçamento', is_active: false } },
                                              headers: admin.create_new_auth_token, as: :json

      expect(response).to have_http_status(:success)
      expect(loss_reason.reload).to have_attributes(name: 'Sem orçamento', is_active: false)
    end

    it 'does not let agents update reasons' do
      patch "#{base_path}/#{loss_reason.id}", params: { loss_reason: { is_active: false } }, headers: agent.create_new_auth_token, as: :json

      expect(response).to have_http_status(:unauthorized)
      expect(loss_reason.reload.is_active).to be(true)
    end

    it 'returns not found for a reason of another account' do
      patch "#{base_path}/#{create(:crm_loss_reason).id}", params: { loss_reason: { name: 'x' } }, headers: admin.create_new_auth_token, as: :json

      expect(response).to have_http_status(:not_found)
    end
  end

  it 'does not expose deletion' do
    delete "#{base_path}/#{create(:crm_loss_reason, account: account).id}", headers: admin.create_new_auth_token, as: :json

    expect(response).to have_http_status(:not_found)
  end
end
