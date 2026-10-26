# Apagar um departamento tira as mensagens rápidas dele de quem o via (US 17, FA 17.1).
module Chatclean::TeamCannedCache
  extend ActiveSupport::Concern

  included do
    after_destroy_commit -> { account.update_cache_key('canned_response') }
  end
end
