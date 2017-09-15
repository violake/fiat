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
      end
    end

    trait :handled do
      after :create do |payment|
        payment.status = "handled"
      end
    end

    trait :archived do
      after :create do |payment|
        payment.status = "archived"
      end
    end

    trait :unreconciled do
      after :create do |payment|
        payment.result = "unreconciled"
      end
    end

    trait :conciled do
      after :create do |payment|
        payment.result = "conciled"
      end
    end

    trait :error do
      after :create do |payment|
        payment.result = "error"
        payment.error_info = "lack of something"
      end
    end


  end

end