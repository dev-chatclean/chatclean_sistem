FactoryBot.define do
  factory :crm_pipeline, class: 'Crm::Pipeline' do
    account
    sequence(:name) { |n| "Pipeline #{n}" }
  end

  factory :crm_stage, class: 'Crm::Stage' do
    pipeline factory: :crm_pipeline
    account { pipeline.account }
    # Estágios abertos; Ganho e Perdido vêm prontos no pipeline (pipeline.stages.won.first).
    sequence(:name) { |n| "Stage #{n}" }
  end

  factory :crm_contact, class: 'Crm::Contact' do
    contact
    account { contact.account }
  end

  factory :crm_loss_reason, class: 'Crm::LossReason' do
    account
    sequence(:name) { |n| "Loss reason #{n}" }

    trait :inactive do
      is_active { false }
    end
  end

  factory :crm_deal, class: 'Crm::Deal' do
    account
    stage { association :crm_stage, pipeline: association(:crm_pipeline, account: account), account: account }
    crm_contact { association :crm_contact, contact: association(:contact, account: account), account: account }
    sequence(:title) { |n| "Deal #{n}" }
    value { 1500 }
  end
end
