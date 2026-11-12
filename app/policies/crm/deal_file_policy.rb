class Crm::DealFilePolicy < ApplicationPolicy
  def create?
    @account_user.administrator? || @account_user.agent?
  end

  def destroy?
    @account_user.administrator? || [record.uploaded_by_id, record.deal.assignee_id].include?(@user.id)
  end
end
