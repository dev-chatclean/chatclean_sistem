require 'rails_helper'

RSpec.describe 'CRM Deals API', type: :request do
  let(:account) { create(:account) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:pipeline) { create(:crm_pipeline, account: account) }
  let(:open_stage) { create(:crm_stage, pipeline: pipeline) }
  let(:lost_stage) { create(:crm_stage, :lost, pipeline: pipeline) }
  let(:contact) { create(:contact, account: account) }
  let(:base_path) { "/api/v1/accounts/#{account.id}/crm/deals" }

  describe 'GET /api/v1/accounts/{account.id}/crm/deals' do
    it 'returns unauthorized for unauthenticated users' do
      get base_path

      expect(response).to have_http_status(:unauthorized)
    end

    it 'lists only the deals of the account, filtered by status' do
      open_deal = create(:crm_deal, account: account, stage: open_stage)
      create(:crm_deal, account: account, stage: create(:crm_stage, :won, pipeline: pipeline))
      create(:crm_deal)

      get base_path, params: { status: 'open' }, headers: agent.create_new_auth_token, as: :json

      expect(response).to have_http_status(:success)
      expect(response.parsed_body['payload'].pluck('id')).to eq([open_deal.id])
      expect(response.parsed_body['meta']['total_count']).to eq(1)
    end

    it 'filters by pipeline and by contact' do
      deal = create(:crm_deal, account: account, stage: open_stage, crm_contact: create(:crm_contact, contact: contact))
      create(:crm_deal, account: account, stage: create(:crm_stage, pipeline: create(:crm_pipeline, account: account)))

      get base_path, params: { crm_pipeline_id: pipeline.id, contact_id: contact.id }, headers: agent.create_new_auth_token, as: :json

      expect(response.parsed_body['payload'].pluck('id')).to eq([deal.id])
    end
  end

  describe 'POST /api/v1/accounts/{account.id}/crm/deals' do
    let(:params) do
      { deal: { title: 'Plano anual', value: '4999.90', expected_close_date: '2026-12-01', crm_stage_id: open_stage.id, contact_id: contact.id } }
    end

    it 'creates a deal linked to the core contact, in BRL, with the status of its stage' do
      post base_path, params: params, headers: agent.create_new_auth_token, as: :json

      expect(response).to have_http_status(:success)
      payload = response.parsed_body['payload']
      expect(payload).to include('title' => 'Plano anual', 'value' => '4999.9', 'currency' => 'BRL', 'status' => 'open',
                                 'contact_id' => contact.id, 'crm_pipeline_id' => pipeline.id)
      expect(Crm::Contact.where(account: account, contact: contact).count).to eq(1)
    end

    it 'returns not found for a contact of another account' do
      post base_path, params: params.deep_merge(deal: { contact_id: create(:contact).id }), headers: agent.create_new_auth_token, as: :json

      expect(response).to have_http_status(:not_found)
    end

    it 'returns not found for a stage of another account' do
      post base_path, params: params.deep_merge(deal: { crm_stage_id: create(:crm_stage).id }), headers: agent.create_new_auth_token, as: :json

      expect(response).to have_http_status(:not_found)
    end

    it 'rejects negative values' do
      post base_path, params: params.deep_merge(deal: { value: '-1' }), headers: agent.create_new_auth_token, as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body['attributes']).to include('value')
    end
  end

  describe 'PATCH /api/v1/accounts/{account.id}/crm/deals/{id}' do
    let(:deal) { create(:crm_deal, account: account, stage: open_stage) }
    let(:loss_reason) { create(:crm_loss_reason, account: account) }

    it 'marks the deal as lost with a loss reason and details' do
      patch "#{base_path}/#{deal.id}",
            params: { deal: { crm_stage_id: lost_stage.id, crm_loss_reason_id: loss_reason.id, loss_details: 'Preço acima do orçamento' } },
            headers: agent.create_new_auth_token, as: :json

      expect(response).to have_http_status(:success)
      expect(response.parsed_body['payload']).to include('status' => 'lost', 'loss_details' => 'Preço acima do orçamento')
      expect(response.parsed_body['payload']['loss_reason']).to eq('id' => loss_reason.id, 'name' => loss_reason.name)
    end

    it 'refuses to lose the deal without a loss reason and keeps it unchanged' do
      patch "#{base_path}/#{deal.id}", params: { deal: { crm_stage_id: lost_stage.id } }, headers: agent.create_new_auth_token, as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body['attributes']).to include('loss_reason')
      expect(deal.reload).to be_open
    end

    it 'refuses an inactive loss reason' do
      patch "#{base_path}/#{deal.id}",
            params: { deal: { crm_stage_id: lost_stage.id, crm_loss_reason_id: create(:crm_loss_reason, :inactive, account: account).id } },
            headers: agent.create_new_auth_token, as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body['message']).to include(I18n.t('errors.crm.deal.inactive_loss_reason'))
    end

    it 'returns not found for a loss reason of another account' do
      patch "#{base_path}/#{deal.id}",
            params: { deal: { crm_stage_id: lost_stage.id, crm_loss_reason_id: create(:crm_loss_reason).id } },
            headers: agent.create_new_auth_token, as: :json

      expect(response).to have_http_status(:not_found)
    end

    it 'reopens a lost deal and clears the loss data' do
      deal.update!(stage: lost_stage, loss_reason: loss_reason, loss_details: 'Sem retorno')

      patch "#{base_path}/#{deal.id}", params: { deal: { crm_stage_id: open_stage.id } }, headers: agent.create_new_auth_token, as: :json

      expect(response.parsed_body['payload']).to include('status' => 'open', 'loss_reason' => nil, 'loss_details' => nil)
    end

    it 'returns not found for a deal of another account' do
      patch "#{base_path}/#{create(:crm_deal).id}", params: { deal: { title: 'x' } }, headers: agent.create_new_auth_token, as: :json

      expect(response).to have_http_status(:not_found)
    end
  end
end
