# Quem entra ou sai de um departamento passa a ver (ou deixa de ver) as mensagens rápidas dele na
# hora (US 17, FA 17.1): a lista fica em cache no navegador e é renovada quando a chave muda.
module Chatclean::TeamMemberCannedCache
  extend ActiveSupport::Concern

  included do
    # Sem o departamento, quem renova a chave é o próprio departamento ao ser apagado (TeamCannedCache).
    after_commit -> { team&.account&.update_cache_key('canned_response') }, on: [:create, :destroy]
  end
end
