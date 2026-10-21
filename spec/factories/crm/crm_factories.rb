FactoryBot.define do
  factory :crm_pipeline, class: 'Crm::Pipeline' do
    account
    sequence(:name) { |n| "Pipeline #{n}" }
  end

  factory :crm_stage, class: 'Crm::Stage' do
    pipeline factory: :crm_pipeline
    account { pipeline.account }
    sequence(:name) { |n| "Stage #{n}" }
    sequence(:position)

    trait :won do
      status { :won }
    end

    trait :lost do
      status { :lost }
    end
  end

  factory :crm_contact, class: 'Crm::Contact' do
    contact
    account { contact.account }
  end

  factory :crm_deal, class: 'Crm::Deal' do
    account
    stage { association :crm_stage, pipeline: association(:crm_pipeline, account: account), account: account }
    crm_contact { association :crm_contact, contact: association(:contact, account: account), account: account }
    sequence(:title) { |n| "Deal #{n}" }
    value { 1500 }
  end
end
