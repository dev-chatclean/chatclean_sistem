# Motivos de fechamento de atendimento (US 16, CCV2-24). O administrador gerencia; o atendente só lista
# os motivos que pode usar ao fechar.
class Api::V1::Accounts::ClosingReasonsController < Api::V1::Accounts::BaseController
  before_action -> { check_authorization(::Chatclean::ClosingReason) }
  before_action :fetch_closing_reason, only: [:update, :destroy]

  def index
    @closing_reasons = account_closing_reasons.available_to(Current.account_user).includes(:teams).ordered
    @closing_reasons = @closing_reasons.active if ActiveModel::Type::Boolean.new.cast(params[:active])
  end

  def create
    @closing_reason = account_closing_reasons.create!(closing_reason_params)
  end

  def update
    @closing_reason.update!(closing_reason_params)
  end

  # Motivo já usado não é excluído, só inativado (CA 16.2).
  def destroy
    @closing_reason.destroy || raise(ActiveRecord::RecordInvalid, @closing_reason)
    head :ok
  end

  private

  def fetch_closing_reason
    @closing_reason = account_closing_reasons.find(params[:id])
  end

  def account_closing_reasons
    ::Chatclean::ClosingReason.where(account: Current.account)
  end

  def closing_reason_params
    permitted = params.require(:closing_reason).permit(:name, :is_active, :closing_message, :ask_sale_value, team_ids: [])
    permitted[:teams] = Current.account.teams.where(id: permitted.delete(:team_ids)) if permitted.key?(:team_ids)
    permitted
  end
end
