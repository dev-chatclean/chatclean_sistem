require 'rails_helper'

RSpec.describe Crm::LoseBlockedContactDealsJob do
  let(:account) { create(:account) }
  let(:contact) { create(:contact, account: account) }
  let(:crm_contact) { create(:crm_contact, contact: contact) }
  let(:pipeline) { create(:crm_pipeline, account: account) }
  let!(:open_deal) { create(:crm_deal, account: account, stage: create(:crm_stage, pipeline: pipeline), crm_contact: crm_contact) }
  let!(:won_deal) { create(:crm_deal, account: account, stage: pipeline.stages.won.first, crm_contact: crm_contact) }

  it 'is enqueued when the contact is blocked' do
    expect { contact.update!(blocked: true) }.to have_enqueued_job(described_class).with(contact.id)
  end

  it 'is not enqueued for other contact changes' do
    expect { contact.update!(name: 'Novo nome') }.not_to have_enqueued_job(described_class)
  end

  it 'loses the open deals with the "contact blocked" reason and keeps won deals' do
    contact.update!(blocked: true)

    described_class.perform_now(contact.id)

    expect(open_deal.reload).to have_attributes(status: 'lost', crm_stage_id: pipeline.stages.lost.first.id)
    expect(open_deal.loss_reason.system_key).to eq(Crm::LossReason::CONTACT_BLOCKED)
    expect(won_deal.reload).to be_won
  end

  it 'does nothing when the contact was unblocked before the job ran' do
    described_class.perform_now(contact.id)

    expect(open_deal.reload).to be_open
  end
end
