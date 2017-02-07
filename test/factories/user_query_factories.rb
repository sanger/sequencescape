FactoryGirl.define do
  factory :user_query do
    user_name 'user_name'
    user { create :user, login: 'user_abc', email: 'user_abc@example.com' }
    url 'www.example.com/some_page'
    what_was_trying_to_do 'create'
    what_happened 'it did not work'
    what_expected 'it to work'
  end
end