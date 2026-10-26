class Crm::DealPolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    true
  end

  def create?
    true
  end

  def update?
    true
  end

  # Trocar o responsável é só do administrador (US 27).
  def assign?
    @account_user.administrator?
  end
end
