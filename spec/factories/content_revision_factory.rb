FactoryBot.define do
  factory :content_revision do
    association :created_by, factory: :user
  end
end
