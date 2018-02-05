FactoryGirl.define do
  factory :transfer_out do
    source_id { Faker::PhoneNumber.phone_number }
    source_name { Faker::StarWars.character }
    source_code { Faker::Lorem.word }
    transfer_type { Faker::StarWars.character }
    amount { Faker::Number.number(10) }
    currency { Faker::StarWars.character }
    result "unreconciled"

    trait :new do
      after :create do |transfer|
        transfer.status = "new"
        transfer.save
      end
    end

    trait :sent do
      after :create do |transfer|
        transfer.status = "sent"
        transfer.save
      end
    end

    trait :archived do
      after :create do |transfer|
        transfer.status = "archived"
        transfer.save
      end
    end

    trait :unreconciled do
      after :create do |transfer|
        transfer.result = "unreconciled"
        transfer.save
      end
    end

    trait :reconciled do
      after :create do |transfer|
        transfer.result = "reconciled"
        transfer.save
      end
    end

    trait :error do
      after :create do |transfer|
        transfer.result = "error"
        transfer.error_info = "lack of something"
        transfer.save
      end
    end

    trait :created_aweekago do
      after :create do |transfer|
        transfer.created_at = Time.now - 7.days
        transfer.save
      end
    end

    trait :created_amonthage do
      after :create do |transfer|
        transfer.created_at = Time.now - 30.days
        transfer.save
      end
    end

    trait :created_now do
      after :create do |transfer|
        transfer.created_at = Time.now
        transfer.save
      end
    end

    factory :new_transfer_out, traits: [:new, :unreconciled, :created_now]
    factory :error_transfer_out, traits: [:new, :error, :created_aweekago]
    factory :reconciled_transfer_out, traits: [:sent, :reconciled, :created_amonthage]
    factory :unreconciled_transfer_out, traits: [:sent, :unreconciled, :created_aweekago]

  end

end