class Crm::DealPolicy < ApplicationPolicy
  def index?
    @account_user.administrator? || @account_user.agent?
  end

  def show?
    index?
  end

  def create?
    index?
  end

  def update?
    index?
  end

  def duplicate?
    index?
  end

  def destroy?
    @account_user.administrator? || record.assignee_id == @user.id
  end

  def reassign?
    @account_user.administrator?
  end
end
