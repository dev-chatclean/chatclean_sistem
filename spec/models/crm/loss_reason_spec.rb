require 'rails_helper'

RSpec.describe Crm::LossReason do
  let(:account) { create(:account) }

  it 'uses the crm_loss_reasons table' do
    expect(described_class.table_name).to eq('crm_loss_reasons')
  end

  context 'with validations' do
    subject { build(:crm_loss_reason, account: account) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to belong_to(:account) }

    it 'does not allow the same name twice in an account, ignoring case' do
      create(:crm_loss_reason, account: account, name: 'Preço alto')

      expect(build(:crm_loss_reason, account: account, name: 'PREÇO ALTO')).not_to be_valid
      expect(build(:crm_loss_reason, name: 'Preço alto')).to be_valid
    end

    it 'enforces the case-insensitive uniqueness in the database' do
      create(:crm_loss_reason, account: account, name: 'Concorrente')
      duplicate = build(:crm_loss_reason, account: account, name: 'concorrente')

      expect { duplicate.save!(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end

  it 'orders by name ignoring case' do
    zebra = create(:crm_loss_reason, account: account, name: 'zebra')
    alpha = create(:crm_loss_reason, account: account, name: 'Alpha')

    expect(described_class.where(account: account).ordered).to eq([alpha, zebra])
  end

  it 'cannot be deleted while deals use it' do
    loss_reason = create(:crm_loss_reason, account: account)
    stage = create(:crm_pipeline, account: account).stages.lost.first
    create(:crm_deal, account: account, stage: stage, loss_reason: loss_reason)

    expect(loss_reason.destroy).to be(false)
    expect(described_class.exists?(loss_reason.id)).to be(true)
  end

  describe '.for_blocked_contact!' do
    it 'creates the protected reason in the account language once' do
      account.update!(locale: 'pt_BR')

      reason = described_class.for_blocked_contact!(account)

      expect(reason).to have_attributes(name: 'Contato bloqueado', system_key: 'contact_blocked', is_active: true)
      expect(described_class.for_blocked_contact!(account)).to eq(reason)
    end

    it 'adopts a manual reason with the same name and reactivates it' do
      manual = create(:crm_loss_reason, :inactive, account: account, name: 'contact blocked')

      expect(described_class.for_blocked_contact!(account)).to eq(manual)
      expect(manual.reload).to have_attributes(system_key: 'contact_blocked', is_active: true)
    end

    it 'cannot be turned off' do
      reason = described_class.for_blocked_contact!(account)

      expect(reason.update(is_active: false)).to be(false)
      expect(reason.errors[:is_active]).to include(I18n.t('errors.crm.loss_reason.system_reason_active'))
    end
  end

  it 'lists only active reasons in the active scope' do
    active = create(:crm_loss_reason, account: account)
    create(:crm_loss_reason, :inactive, account: account)

    expect(described_class.active).to eq([active])
  end
end
