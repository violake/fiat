FactoryGirl.define do
  factory :withdraw do
    account_id { Faker::Number.number(6) }
    member_id { Faker::Number.number(6) }
    currency { Faker::Lorem.word }
    amount { Faker::Number.number(4) }
    fee { Faker::Number.number(2) }
    sum { amount.to_f + fee.to_f }
    aasm_state { :accepted }
  end
end