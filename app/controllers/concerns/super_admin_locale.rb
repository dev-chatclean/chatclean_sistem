# ChatClean (CCV2-22): idioma do Super Admin, escolhido no menu do perfil e guardado num cookie.
# Sem cookie vale o DEFAULT_LOCALE da instalação, como no painel.
module SuperAdminLocale
  extend ActiveSupport::Concern
  include SwitchLocale

  COOKIE = 'super_admin_locale'.freeze
  LOCALES = %w[en pt_BR].freeze

  included do
    around_action :switch_super_admin_locale
  end

  private

  def switch_super_admin_locale(&)
    set_locale(cookies[COOKIE].presence_in(LOCALES) || ENV.fetch('DEFAULT_LOCALE', nil), &)
  end
end
