# ChatClean: Puma e Sidekiq nao sobem sem Redis (ActionCable e filas dependem dele).
# Sem este check o pool do $alfred conecta sob demanda e o processo sobe "saudavel".
# Restrito ao servidor e ao worker para nao afetar rake tasks como assets:precompile.
Rails.application.config.after_initialize do
  next unless defined?(Rails::Server) || Sidekiq.server?

  begin
    Redis.new(Redis::Config.app).ping
  rescue Redis::BaseConnectionError => e
    target = URI.parse(Redis::Config.app[:url]).tap { |uri| uri.userinfo = nil }
    raise "[ChatClean] Redis heartbeat ausente em #{target} (#{e.class}: #{e.message}). Boot abortado."
  end
end
