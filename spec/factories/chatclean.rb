FactoryBot.define do
  factory :chatclean_closing_reason, class: 'Chatclean::ClosingReason' do
    account
    sequence(:name) { |n| "Closing reason #{n}" }

    trait :sale do
      ask_sale_value { true }
    end
  end
end
