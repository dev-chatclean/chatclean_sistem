require 'rails_helper'

RSpec.describe 'CRM Pipelines API', type: :request do
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:base_path) { "/api/v1/accounts/#{account.id}/crm/pipelines" }

  describe 'GET /api/v1/accounts/{account.id}/crm/pipelines' do
    it 'returns unauthorized for unauthenticated users' do
      get base_path

      expect(response).to have_http_status(:unauthorized)
    end

    it 'lists the account pipelines with their stages, default first, for agents too' do
      create(:crm_pipeline, account: account, name: 'Alpha')
      default = create(:crm_pipeline, account: account, name: 'Zeta', is_default: true)
      create(:crm_stage, pipeline: default, name: 'Proposta', probability: 60)
      create(:crm_pipeline, name: 'Outra conta')

      get base_path, headers: agent.create_new_auth_token, as: :json

      expect(response).to have_http_status(:success)
      payload = response.parsed_body['payload']
      expect(payload.pluck('name')).to eq(%w[Zeta Alpha])
      expect(payload.first['stages'].map { |stage| stage.slice('name', 'status', 'probability') })
        .to eq([{ 'name' => 'Proposta', 'status' => 'open', 'probability' => 60 },
                { 'name' => 'Won', 'status' => 'won', 'probability' => 100 },
                { 'name' => 'Lost', 'status' => 'lost', 'probability' => 0 }])
    end
  end

  describe 'GET /api/v1/accounts/{account.id}/crm/pipelines/{id}' do
    it 'returns not found for a pipeline of another account' do
      get "#{base_path}/#{create(:crm_pipeline).id}", headers: agent.create_new_auth_token, as: :json

      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'GET /api/v1/accounts/{account.id}/crm/pipelines/{id}/summary' do
    let(:pipeline) { create(:crm_pipeline, account: account) }
    let(:stage) { create(:crm_stage, pipeline: pipeline) }

    it 'returns the count and total value of deals for every stage, in order' do
      create(:crm_deal, account: account, stage: stage, value: 1000, assignee: agent)
      create(:crm_deal, account: account, stage: stage, value: 500.5)

      get "#{base_path}/#{pipeline.id}/summary", headers: agent.create_new_auth_token, as: :json

      expect(response.parsed_body['payload']).to eq([
                                                      { 'crm_stage_id' => stage.id, 'deals_count' => 2, 'total_value' => '1500.5' },
                                                      { 'crm_stage_id' => pipeline.stages.won.first.id, 'deals_count' => 0, 'total_value' => '0' },
                                                      { 'crm_stage_id' => pipeline.stages.lost.first.id, 'deals_count' => 0, 'total_value' => '0' }
                                                    ])
    end

    it 'applies the assignee filter' do
      create(:crm_deal, account: account, stage: stage, value: 1000, assignee: agent)
      create(:crm_deal, account: account, stage: stage, value: 500)

      get "#{base_path}/#{pipeline.id}/summary", params: { assignee_id: agent.id }, headers: agent.create_new_auth_token, as: :json

      expect(response.parsed_body['payload'].first).to include('deals_count' => 1, 'total_value' => '1000.0')
    end
  end

  describe 'POST /api/v1/accounts/{account.id}/crm/pipelines' do
    it 'creates the pipeline with the won and lost stages' do
      post base_path, params: { pipeline: { name: 'Vendas Inbound', is_default: true } }, headers: admin.create_new_auth_token, as: :json

      expect(response).to have_http_status(:success)
      expect(response.parsed_body['payload']).to include('name' => 'Vendas Inbound', 'is_default' => true)
      expect(response.parsed_body['payload']['stages'].pluck('status')).to eq(%w[won lost])
    end

    it 'moves the default flag from the previous default pipeline' do
      previous = create(:crm_pipeline, account: account, is_default: true)

      post base_path, params: { pipeline: { name: 'Novo padrão', is_default: true } }, headers: admin.create_new_auth_token, as: :json

      expect(previous.reload.is_default).to be(false)
    end

    it 'does not let agents create pipelines' do
      post base_path, params: { pipeline: { name: 'Vendas' } }, headers: agent.create_new_auth_token, as: :json

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe 'PATCH /api/v1/accounts/{account.id}/crm/pipelines/{id}' do
    it 'renames the pipeline' do
      pipeline = create(:crm_pipeline, account: account)

      patch "#{base_path}/#{pipeline.id}", params: { pipeline: { name: 'Vendas Outbound' } }, headers: admin.create_new_auth_token, as: :json

      expect(pipeline.reload.name).to eq('Vendas Outbound')
    end
  end

  describe 'DELETE /api/v1/accounts/{account.id}/crm/pipelines/{id}' do
    let(:pipeline) { create(:crm_pipeline, account: account) }

    it 'deletes a pipeline without deals, with its stages' do
      delete "#{base_path}/#{pipeline.id}", headers: admin.create_new_auth_token, as: :json

      expect(response).to have_http_status(:success)
      expect(Crm::Stage.where(crm_pipeline_id: pipeline.id)).to be_empty
    end

    it 'refuses to delete a pipeline that has deals' do
      create(:crm_deal, account: account, stage: pipeline.stages.won.first)

      delete "#{base_path}/#{pipeline.id}", headers: admin.create_new_auth_token, as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body['attributes']).to eq(['base'])
      expect(Crm::Pipeline.exists?(pipeline.id)).to be(true)
    end

    it 'does not let agents delete pipelines' do
      delete "#{base_path}/#{pipeline.id}", headers: agent.create_new_auth_token, as: :json

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
