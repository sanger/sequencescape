# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    trait :with_role do
      transient { role_name { 'role' } }
      roles { |role| [role.association(:role, name: role_name)] }
    end

    first_name { 'first_name' }
    last_name { 'last_name' }
    login
    email { "#{login}@example.com".downcase }
    api_key { '123456789' }
    password { 'password' }
    password_confirmation { 'password' }

    factory :admin do
      roles { |role| [role.association(:admin_role)] }
    end

    factory :manager do
      roles { |role| Array(authorizable).map { |auth| role.association(:manager_role, authorizable: auth) } }

      transient { authorizable { create(:study) } }
    end

    factory :owner do
      roles { |role| [role.association(:owner_role)] }
    end

    factory :data_access_coordinator do
      roles { |role| [role.association(:data_access_coordinator_role)] }
    end

    factory :slf_manager do
      roles { |role| [role.association(:slf_manager_role)] }
    end

    factory :listing_studies_user do
      login { 'listing_studies_user' }
    end
  end
end
