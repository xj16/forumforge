# frozen_string_literal: true

FactoryBot.define do
  factory :vote do
    association :user
    association :votable, factory: :topic
  end
end
