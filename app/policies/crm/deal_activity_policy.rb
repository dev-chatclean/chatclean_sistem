class Crm::DealActivityPolicy < ApplicationPolicy
  def create?
    @account_user.administrator? || @account_user.agent?
  end

  def update?
    create?
  end

  def destroy?
    @account_user.administrator? || [record.assignee_id, record.deal.assignee_id].include?(@user.id)
  end

  def reassign?
    @account_user.administrator?
  end
end
