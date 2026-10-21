# Motivos de perda da conta. Não há exclusão: para aposentar um motivo, envie is_active: false (CA 5.7).
class Api::V1::Accounts::Crm::LossReasonsController < Api::V1::Accounts::BaseController
  before_action -> { check_authorization(::Crm::LossReason) }
  before_action :fetch_loss_reason, only: [:update]

  def index
    @loss_reasons = account_loss_reasons.ordered
    @loss_reasons = @loss_reasons.active if ActiveModel::Type::Boolean.new.cast(params[:active])
  end

  def create
    @loss_reason = account_loss_reasons.create!(loss_reason_params.slice(:name, :description))
  end

  def update
    @loss_reason.update!(loss_reason_params)
  end

  private

  def fetch_loss_reason
    @loss_reason = account_loss_reasons.find(params[:id])
  end

  def account_loss_reasons
    ::Crm::LossReason.where(account: Current.account)
  end

  def loss_reason_params
    params.require(:loss_reason).permit(:name, :description, :is_active)
  end
end
