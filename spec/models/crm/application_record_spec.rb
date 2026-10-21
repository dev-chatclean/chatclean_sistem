require 'rails_helper'

RSpec.describe Crm::ApplicationRecord do
  it 'is an abstract base for CRM models' do
    expect(described_class).to be_abstract_class
    expect(described_class.superclass).to eq(ApplicationRecord)
  end

  it 'prefixes the table names of its models with crm_' do
    model = Class.new(described_class) { def self.name = 'Crm::Deal' }

    expect(model.table_name).to eq('crm_deals')
  end
end
