class Chatclean::AccountSchedulePolicy < ApplicationPolicy
  def show?
    true
  end

  def update?
    @account_user.administrator?
  end
end
