require 'rails_helper'

RSpec.describe 'CRM Stages API', type: :request do
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:pipeline) { create(:crm_pipeline, account: account) }
  let(:base_path) { "/api/v1/accounts/#{account.id}/crm/pipelines/#{pipeline.id}/stages" }
  let(:won) { pipeline.stages.won.first }

  it 'lists the stages of the pipeline in order' do
    stage = create(:crm_stage, pipeline: pipeline)

    get base_path, headers: agent.create_new_auth_token, as: :json

    expect(response.parsed_body['payload'].pluck('id')).to eq([stage.id, won.id, pipeline.stages.lost.first.id])
  end

  it 'returns not found for a pipeline of another account' do
    get "/api/v1/accounts/#{account.id}/crm/pipelines/#{create(:crm_pipeline).id}/stages", headers: admin.create_new_auth_token, as: :json

    expect(response).to have_http_status(:not_found)
  end

  describe 'POST' do
    it 'creates an open stage before won and lost' do
      post base_path, params: { stage: { name: 'Qualificação', probability: 20 } }, headers: admin.create_new_auth_token, as: :json

      expect(response).to have_http_status(:success)
      expect(response.parsed_body['payload']).to include('name' => 'Qualificação', 'status' => 'open', 'probability' => 20)
      expect(pipeline.stages.reload.first.name).to eq('Qualificação')
    end

    it 'refuses a second won stage' do
      post base_path, params: { stage: { name: 'Ganho 2', status: 'won' } }, headers: admin.create_new_auth_token, as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body['attributes']).to eq(['status'])
    end

    it 'refuses a probability above 100' do
      post base_path, params: { stage: { name: 'Proposta', probability: 120 } }, headers: admin.create_new_auth_token, as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body['attributes']).to eq(['probability'])
    end

    it 'does not let agents create stages' do
      post base_path, params: { stage: { name: 'Proposta' } }, headers: agent.create_new_auth_token, as: :json

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe 'PATCH' do
    it 'renames the won stage' do
      patch "#{base_path}/#{won.id}", params: { stage: { name: 'Fechado' } }, headers: admin.create_new_auth_token, as: :json

      expect(response).to have_http_status(:success)
      expect(won.reload.name).to eq('Fechado')
    end

    it 'refuses to change the status or probability of the won stage' do
      patch "#{base_path}/#{won.id}", params: { stage: { status: 'open', probability: 50 } }, headers: admin.create_new_auth_token, as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body['attributes']).to include('base')
      expect(won.reload).to have_attributes(status: 'won', probability: 100)
    end
  end

  describe 'DELETE' do
    it 'refuses to delete the won stage' do
      delete "#{base_path}/#{won.id}", headers: admin.create_new_auth_token, as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body['attributes']).to eq(['base'])
    end

    it 'refuses to delete a stage with deals' do
      stage = create(:crm_stage, pipeline: pipeline)
      create(:crm_deal, account: account, stage: stage)

      delete "#{base_path}/#{stage.id}", headers: admin.create_new_auth_token, as: :json

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'deletes an open stage without deals' do
      stage = create(:crm_stage, pipeline: pipeline)

      delete "#{base_path}/#{stage.id}", headers: admin.create_new_auth_token, as: :json

      expect(response).to have_http_status(:success)
      expect(Crm::Stage.exists?(stage.id)).to be(false)
    end
  end

  describe 'POST reorder' do
    let!(:first) { create(:crm_stage, pipeline: pipeline) }
    let!(:second) { create(:crm_stage, pipeline: pipeline) }

    it 'reorders the open stages and keeps won and lost at the end' do
      post "#{base_path}/reorder", params: { stage_ids: [second.id, first.id] }, headers: admin.create_new_auth_token, as: :json

      expect(response).to have_http_status(:success)
      expect(response.parsed_body['payload'].pluck('id')).to eq([second.id, first.id, won.id, pipeline.stages.lost.first.id])
    end

    it 'refuses an incomplete list and keeps the order' do
      post "#{base_path}/reorder", params: { stage_ids: [second.id] }, headers: admin.create_new_auth_token, as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body['attributes']).to eq(['base'])
      expect(pipeline.stages.reload.first(2)).to eq([first, second])
    end

    it 'refuses stages of another pipeline' do
      other = create(:crm_stage, pipeline: create(:crm_pipeline, account: account))

      post "#{base_path}/reorder", params: { stage_ids: [first.id, other.id] }, headers: admin.create_new_auth_token, as: :json

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'does not let agents reorder' do
      post "#{base_path}/reorder", params: { stage_ids: [second.id, first.id] }, headers: agent.create_new_auth_token, as: :json

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
