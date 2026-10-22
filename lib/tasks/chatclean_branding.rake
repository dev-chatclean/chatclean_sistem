# Marca ChatClean nas configurações da instalação (CCV2-18). Rode depois de preparar o banco
# (db:chatwoot_prepare) e a cada deploy; aplicar de novo não muda nada.
# Só funciona com DISABLE_ENTERPRISE=true: no plano community, o código de enterprise/
# devolve esses valores para os do Chatwoot.
namespace :chatclean do
  desc 'Aplica nome, logos e links da ChatClean nas configurações da instalação'
  task branding: :environment do
    branding = {
      'INSTALLATION_NAME' => 'ChatClean',
      'BRAND_NAME' => 'ChatClean',
      'LOGO' => '/brand-assets/chatclean/logo.png',
      'LOGO_DARK' => '/brand-assets/chatclean/logo-dark.png',
      'LOGO_THUMBNAIL' => '/brand-assets/chatclean/logo-thumbnail.png',
      'BRAND_URL' => 'https://chatclean.com.br',
      'WIDGET_BRAND_URL' => 'https://chatclean.com.br',
      # A ChatClean ainda não publicou páginas próprias de termos e privacidade.
      'TERMS_URL' => 'https://chatclean.com.br',
      'PRIVACY_URL' => 'https://chatclean.com.br',
      # Esconde os favicons e avisos de versão do Chatwoot; o favicon passa a ser o LOGO_THUMBNAIL.
      'DISPLAY_MANIFEST' => false
    }

    branding.each do |name, value|
      InstallationConfig.find_or_initialize_by(name: name).update!(value: value)
    end
    puts "Marca ChatClean aplicada em #{branding.size} configurações."
  end
end
