FactoryGirl.define do
  factory :deposit do
    account_id { Faker::Number.number(6) }
    member_id { Faker::Number.number(6) }
    currency { Faker::Lorem.word }
    lodged_amount { Faker::Number.number(10) }
    aasm_state { Faker::Lorem.word }

    trait :accepted do
      aasm_state "accepted"
    end

    trait :submitting do
      aasm_state "submitting"
    end

    factory :accepted_deposit, traits: [:accepted]
    factory :submitting_deposit, traits: [:submitting]
  end
end