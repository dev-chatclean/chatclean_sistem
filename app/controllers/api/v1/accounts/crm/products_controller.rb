class Api::V1::Accounts::Crm::ProductsController < Api::V1::Accounts::BaseController
  before_action :fetch_product, except: [:index, :create]
  before_action :check_authorization

  def index
    @products = Current.account.crm_products.order(:name)
  end

  def create
    @product = Current.account.crm_products.create!(product_params)
    render :show
  end

  def update
    @product.update!(product_params)
    render :show
  end

  def destroy
    return render_could_not_create_error(I18n.t('crm.products.errors.in_use')) if @product.deal_products.exists?

    @product.destroy!
    head :ok
  end

  private

  def fetch_product
    @product = Current.account.crm_products.find(params[:id])
  end

  def check_authorization
    authorize(@product || Crm::Product)
  end

  def product_params
    params.require(:product).permit(:name, :description, :price, :sku, :active)
  end
end
