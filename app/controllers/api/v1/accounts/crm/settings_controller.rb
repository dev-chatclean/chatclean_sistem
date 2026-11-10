class Api::V1::Accounts::Crm::SettingsController < Api::V1::Accounts::BaseController
  SETTING_KEYS = { 'auto_create_deals' => :crm_auto_create_deals, 'lead_entry' => :crm_lead_entry, 'ai' => :crm_ai }.freeze

  before_action :check_admin_authorization?

  def show; end

  def update
    Current.account.update!(settings_params)
    render :show
  end

  private

  def settings_params
    params.require(:crm)
          .permit(:auto_create_deals,
                  lead_entry: [:alert_after_days, { inbox_ids: [], origins: [], sources: [] }],
                  ai: [:next_step, :fill_on_move, :temperature, :monthly_cap])
          .to_h
          .transform_keys(SETTING_KEYS)
  end
end
