require 'rails_helper'

RSpec.describe 'Super Admin locale', type: :request do
  let(:super_admin) { create(:super_admin) }

  it 'uses the language saved in the cookie' do
    cookies[SuperAdminLocale::COOKIE] = 'pt_BR'
    get '/super_admin/sign_in'
    expect(response.body).to include('Olá, admin')
  end

  it 'keeps the default language without the cookie' do
    get '/super_admin/sign_in'
    expect(response.body).to include('Howdy, admin')
  end

  it 'ignores a language outside the selector' do
    cookies[SuperAdminLocale::COOKIE] = 'fr'
    sign_in(super_admin, scope: :super_admin)
    get '/super_admin/accounts'
    expect(response.body).to include('lang="en"')
  end
end
