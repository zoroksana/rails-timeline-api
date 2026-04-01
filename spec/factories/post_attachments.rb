FactoryBot.define do
  factory :post_attachment do
    association :post
    file_type { "photo" }
    sequence(:url) { |n| "https://cdn.example.com/files/#{n}.jpg" }
  end
end
