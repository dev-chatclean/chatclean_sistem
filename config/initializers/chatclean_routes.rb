# Rotas do atendimento no padrão ChatClean (E8), anexadas fora do config/routes.rb do Chatwoot para
# não gerar conflito nos syncs com o upstream. Ficam em
# /api/v1/accounts/:account_id/conversations/:conversation_id/... (número do atendimento).
Rails.application.routes.append do
  namespace :api, defaults: { format: 'json' } do
    namespace :v1 do
      resources :accounts, only: [] do
        scope module: :accounts do
          resources :closing_reasons, only: [:index, :create, :update, :destroy]
          resources :conversations, only: [] do
            scope module: :conversations do
              resource :acceptance, only: [:create]
              resource :transfer, only: [:create]
            end
          end
        end
      end
    end
  end
end
