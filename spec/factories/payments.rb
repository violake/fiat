FactoryGirl.define do
  factory :payment do
    source_id { Faker::PhoneNumber.phone_number }
    source_name { Faker::StarWars.character }
    source_code { Faker::Lorem.word }
    payment_type { Faker::StarWars.character }
    amount { Faker::Number.number(10) }
    currency { Faker::StarWars.character }
    result "unreconciled"

    trait :new do
      after :create do |payment|
        payment.status = "new"
        payment.save
      end
    end

    trait :sent do
      after :create do |payment|
        payment.status = "sent"
        payment.save
      end
    end

    trait :archived do
      after :create do |payment|
        payment.status = "archived"
        payment.save
      end
    end

    trait :unreconciled do
      after :create do |payment|
        payment.result = "unreconciled"
        payment.save
      end
    end

    trait :reconciled do
      after :create do |payment|
        payment.result = "reconciled"
        payment.save
      end
    end

    trait :error do
      after :create do |payment|
        payment.result = "error"
        payment.error_info = "lack of something"
        payment.save
      end
    end

    factory :new_payment, traits: [:new, :unreconciled]
    factory :error_payment, traits: [:new, :error]
    factory :reconciled_payment, traits: [:sent, :reconciled]
    factory :unreconciled_payment, traits: [:sent, :unreconciled]

  end

end