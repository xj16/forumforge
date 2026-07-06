# frozen_string_literal: true

FactoryBot.define do
  factory :post do
    association :user
    association :topic
    body { "This is a thoughtful reply to the topic." }

    trait :reply_to do
      transient do
        to { nil }
      end
      after(:build) do |post, evaluator|
        if evaluator.to
          post.parent = evaluator.to
          post.topic = evaluator.to.topic
        end
      end
    end
  end
end
