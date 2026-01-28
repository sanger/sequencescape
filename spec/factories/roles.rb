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
    transient { owner { build(:user) } }
    roles { |role| [role.association(:role, name: 'owner', users: [owner])] }
  end

  trait :with_manager do
    transient { manager { build(:user) } }
    roles { |role| [role.association(:role, name: 'manager', users: [manager])] }
  end

  trait :with_follower do
    transient { follower { build(:user) } }
    roles { |role| [role.association(:role, name: 'follower', users: [follower])] }
  end

  trait :with_data_access_contacts do
    transient { data_access_contacts { build_list(:user, 1) } }
    roles { |role| [role.association(:role, name: 'Data Access Contact', users: data_access_contacts)] }
  end
end
