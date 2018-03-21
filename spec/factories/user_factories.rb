# frozen_string_literal: true

FactoryGirl.define do
  factory :user do
    first_name        'fn'
    last_name         'ln'
    login
    email             { "#{login}@example.com".downcase }
    api_key           '123456789'
    password              'password'
    password_confirmation 'password'

    factory :admin do
      roles { |role| [role.association(:admin_role)] }
    end

    factory :manager do
      roles { |role| Array(authorizable).map { |auth| role.association(:manager_role, authorizable: auth) } }

      transient do
        authorizable { create :study }
      end
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
      login 'listing_studies_user'
    end
  end
end
