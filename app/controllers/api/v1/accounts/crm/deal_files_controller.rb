class Api::V1::Accounts::Crm::DealFilesController < Api::V1::Accounts::BaseController
  before_action :fetch_deal
  before_action :fetch_file, only: [:destroy]
  before_action :check_authorization

  def create
    @deal_file = @deal.files.create!(category: params.require(:category), file: params.require(:file), uploaded_by: Current.user)
    render :show
  end

  def destroy
    @deal_file.destroy!
    head :ok
  end

  private

  def fetch_deal
    @deal = Current.account.crm_deals.find(params[:deal_id])
  end

  def fetch_file
    @deal_file = @deal.files.find(params[:id])
  end

  def check_authorization
    authorize(@deal_file || Crm::DealFile)
  end
end
