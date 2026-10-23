# Marca da instalação nas telas renderizadas pelo Rails, como o Super Admin e a configuração
# inicial (CCV2-22). Lê o que a tarefa chatclean:branding grava e, sem essa configuração,
# usa os arquivos padrão que vêm no repositório.
module ChatcleanBrand
  DEFAULTS = {
    'INSTALLATION_NAME' => 'Chatwoot',
    'LOGO' => '/brand-assets/logo.svg',
    'LOGO_DARK' => '/brand-assets/logo_dark.svg',
    'LOGO_THUMBNAIL' => '/brand-assets/logo_thumbnail.svg'
  }.freeze

  def self.value(name)
    GlobalConfig.get_value(name).presence || DEFAULTS.fetch(name)
  end
end
