# frozen_string_literal: true

FactoryBot.define do
  factory :topic do
    association :user
    association :category
    sequence(:title) { |n| "An interesting discussion number #{n}" }
    body { "Here is the body of the topic with enough content." }

    trait :link do
      body { nil }
      url { "https://example.com/article" }
    end
  end
end
