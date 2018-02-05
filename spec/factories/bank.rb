require_relative '../../app/models/transfer_ins/bank'

FactoryGirl.define do
  factory :bank, :class => Fiat::TransferIns::Bank do |bank|
    bank.source_id { Faker::PhoneNumber.phone_number }
    bank.source_name { Faker::StarWars.character }
    bank.source_code { Faker::Lorem.word }
    bank.transfer_type { Faker::StarWars.character }
    bank.amount { Faker::Number.number(10) }
    bank.currency { Faker::StarWars.character }
    bank.result "unreconciled"
  end
end