# Rotas do CRM do ChatClean, anexadas fora do config/routes.rb do Chatwoot para não gerar
# conflito nos syncs com o upstream. Ficam em /api/v1/accounts/:account_id/crm/...
Rails.application.routes.append do
  namespace :api, defaults: { format: 'json' } do
    namespace :v1 do
      resources :accounts, only: [] do
        scope module: :accounts do
          namespace :crm do
            resources :deals, only: [:index, :show, :create, :update]
            resources :loss_reasons, only: [:index, :create, :update]
            resources :pipelines, only: [:index, :show, :create, :update, :destroy] do
              get :summary, on: :member
              resources :stages, only: [:index, :create, :update, :destroy] do
                post :reorder, on: :collection
              end
            end
          end
        end
      end
    end
  end
end
