# frozen_string_literal: true

FactoryBot.define do
  factory :internal_note do
    content { Faker::Lorem.sentence }

    association :creator, factory: :user
    ticket { FactoryBot.build(:internal_ticket).base_ticket }
  end
end
