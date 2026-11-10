class Api::V1::Accounts::Crm::SettingsController < Api::V1::Accounts::BaseController
  before_action :check_admin_authorization?

  def show; end

  def update
    Current.account.update!(crm_auto_create_deals: params.fetch(:crm_auto_create_deals))
    render :show
  end
end
