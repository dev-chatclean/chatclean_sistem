# Mensagens rápidas por departamento e por usuário, com anexos (US 17, CCV2-25), incluídas no
# CannedResponsesController do Chatwoot pelo initializer chatclean_hooks. O atendente cria só "Só eu"
# e mexe só nas suas; o administrador mexe em qualquer uma, sem trocar o dono.
module Chatclean::CannedResponsesControllerScope
  def create
    @canned_response = Current.account.canned_responses.new(canned_response_params.merge(owner: Current.user))
    @canned_response.attachments.attach(new_attachments)
    @canned_response.save!
    render json: @canned_response
  end

  def update
    ensure_can_manage!
    ActiveRecord::Base.transaction do
      @canned_response.attachments.where(id: params.dig(:canned_response, :remove_attachment_ids)).destroy_all
      @canned_response.attachments_attachments.reset
      @canned_response.assign_attributes(canned_response_params)
      @canned_response.owner ||= Current.user
      @canned_response.attachments.attach(new_attachments)
      @canned_response.save!
    end
    render json: @canned_response
  end

  def destroy
    ensure_can_manage!
    super
  end

  private

  def canned_responses
    super.available_to(Current.account_user, include_personal: ActiveModel::Type::Boolean.new.cast(params[:include_personal]))
         .includes(:owner, :teams, attachments_attachments: :blob)
  end

  def canned_response_params
    permitted = params.require(:canned_response).permit(:short_code, :content, :visibility, team_ids: [])
    permitted[:teams] = Current.account.teams.where(id: permitted.delete(:team_ids)) if permitted.key?(:team_ids)
    permitted[:visibility] = :personal unless Current.account_user.administrator?
    permitted
  end

  def new_attachments
    params.dig(:canned_response, :attachments) || []
  end

  def ensure_can_manage!
    return if Current.account_user.administrator? || @canned_response.owner_id == Current.user.id

    raise Pundit::NotAuthorizedError
  end
end
