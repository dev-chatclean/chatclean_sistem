class Api::V1::Accounts::Contacts::ArchivesController < Api::V1::Accounts::Contacts::BaseController
  before_action -> { authorize(@contact, :update?) }

  def create
    @contact.update!(archived_at: Time.current)
    render template: 'api/v1/accounts/contacts/show'
  end

  def destroy
    @contact.update!(archived_at: nil)
    render template: 'api/v1/accounts/contacts/show'
  end
end
