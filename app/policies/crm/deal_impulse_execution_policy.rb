class Crm::DealImpulseExecutionPolicy < ApplicationPolicy
  def destroy?
    @account_user.administrator? || record.deal.assignee_id == @user.id
  end
end
