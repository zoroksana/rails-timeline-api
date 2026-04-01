FactoryBot.define do
  factory :post do
    association :user
    sequence(:date) { |n| Time.zone.parse("2026-03-31 12:00:00") + n.hours }
    description { Faker::Lorem.paragraph(sentence_count: 2) }

    trait :with_attachments do
      after(:create) do |post|
        create(:post_attachment, post: post, file_type: "photo")
      end
    end
  end
end
