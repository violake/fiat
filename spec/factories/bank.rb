require_relative '../../app/models/payments/bank'

FactoryGirl.define do
  factory :bank, :class => Fiat::Payments::Bank do |bank|
    bank.source_id { Faker::PhoneNumber.phone_number }
    bank.source_name { Faker::StarWars.character }
    bank.source_code { Faker::Lorem.word }
    bank.payment_type { Faker::StarWars.character }
    bank.amount { Faker::Number.number(10) }
    bank.currency { Faker::StarWars.character }
    bank.result "unreconciled"
  end
end