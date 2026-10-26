FactoryBot.define do
  factory :chatclean_closing_reason, class: 'Chatclean::ClosingReason' do
    account
    sequence(:name) { |n| "Closing reason #{n}" }

    trait :sale do
      ask_sale_value { true }
    end
  end

  factory :chatclean_holiday, class: 'Chatclean::Holiday' do
    account
    sequence(:date) { |n| Date.new(2030, 1, 1) + n.days }
    name { 'Feriado' }
  end
end
