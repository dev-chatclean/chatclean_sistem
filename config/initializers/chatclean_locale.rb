# Idioma padrão do sistema na ChatClean: segue o DEFAULT_LOCALE (pt_BR na produção). O Chatwoot só usa
# essa variável para contas novas e requisições sem conta; aqui ela também vale para o que é gerado
# fora de uma requisição, como a mensagem do fechamento automático por inatividade e os e-mails de jobs.
# Sem a variável (testes), continua o inglês. Na produção, o que faltar em português cai no inglês
# (config.i18n.fallbacks em production.rb).
Rails.application.config.i18n.default_locale = ENV.fetch('DEFAULT_LOCALE', 'en').to_sym
