# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    sequence(:username) { |n| "user#{n}" }
    sequence(:email) { |n| "user#{n}@example.com" }
    password { "password123" }
    password_confirmation { "password123" }
    role { "member" }

    trait :admin do
      role { "admin" }
    end

    trait :moderator do
      role { "moderator" }
    end
  end
end
