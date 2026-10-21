require 'rails_helper'

RSpec.describe Crm::Contact do
  let(:contact) { create(:contact) }

  it 'uses the crm_contacts table' do
    expect(described_class.table_name).to eq('crm_contacts')
  end

  context 'with validations' do
    it 'links each core contact only once per account' do
      create(:crm_contact, contact: contact)

      expect(build(:crm_contact, contact: contact)).not_to be_valid
    end

    it 'rejects a core contact from another account' do
      expect(build(:crm_contact, contact: contact, account: create(:account))).not_to be_valid
    end

    it 'enforces the 1:1 link in the database' do
      create(:crm_contact, contact: contact)
      duplicate = build(:crm_contact, contact: contact)

      expect { duplicate.save!(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end

  describe '.for_contact!' do
    it 'creates the link on first use' do
      expect { described_class.for_contact!(contact) }.to change(described_class, :count).by(1)
    end

    it 'returns the existing link instead of creating another one' do
      existing = create(:crm_contact, contact: contact)

      expect(described_class.for_contact!(contact)).to eq(existing)
    end

    it 'returns the record created by a concurrent request' do
      existing = create(:crm_contact, contact: contact)
      allow(described_class).to receive(:find_or_create_by!).and_raise(ActiveRecord::RecordNotUnique)

      expect(described_class.for_contact!(contact)).to eq(existing)
    end
  end

  it 'is removed with its deals when the core contact is deleted' do
    deal = create(:crm_deal, account: contact.account, crm_contact: create(:crm_contact, contact: contact))

    contact.destroy!

    expect(described_class.exists?(deal.crm_contact_id)).to be(false)
    expect(Crm::Deal.exists?(deal.id)).to be(false)
  end
end
