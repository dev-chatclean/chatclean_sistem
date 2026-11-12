class Api::V1::Accounts::Crm::DealImpulseExecutionsController < Api::V1::Accounts::BaseController
  def destroy
    deal = Current.account.crm_deals.find(params[:deal_id])
    execution = deal.impulse_executions.scheduled.find(params[:id])
    authorize(execution)
    deal.cancel_impulse_executions([execution], 'canceled_by_user')
    head :ok
  end
end
