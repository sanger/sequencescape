# frozen_string_literal: true

FactoryBot.define do
  factory :role do
    sequence(:name) { |i| "Role #{i}" }
    authorizable { nil }

    factory :admin_role do
      name { 'administrator' }
    end

    factory :public_role do
      name { 'public' }
    end

    factory :manager_role do
      name { 'manager' }
    end

    factory :data_access_coordinator_role do
      name { 'data_access_coordinator' }
    end

    factory :owner_role do
      name { 'owner' }
      authorizable { |i| i.association(:project) }
    end

    factory :slf_manager_role do
      name { 'slf_manager' }
    end
  end

  trait :with_owner do
    transient do
      owner { build :user }
    end
    roles { |role| [role.association(:role, name: 'owner', users: [owner])] }
  end

  trait :with_manager do
    transient do
      manager { build :user }
    end
    roles { |role| [role.association(:role, name: 'manager', users: [manager])] }
  end

  trait :with_follower do
    transient do
      follower { build :user }
    end
    roles { |role| [role.association(:role, name: 'follower', users: [follower])] }
  end
end
