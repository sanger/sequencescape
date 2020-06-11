# frozen_string_literal: true

FactoryBot.define do
  factory :robot do
    name      { 'myrobot' }
    location  { 'lab' }

    factory :robot_with_verification_behaviour do
      transient do
        verification_behaviour_value { 'SourceDestBeds' }
      end
      robot_properties { build_list :validation_property, 1, value: verification_behaviour_value }
    end

    factory :robot_with_generation_behaviour do
      transient do
        generation_behaviour_value { 'Tecan' }
      end
      robot_properties { build_list :generation_property, 1, value: generation_behaviour_value }
    end
  end

  factory :robot_property do
    name      { 'myrobot' }
    value     { 'lab' }
    key       { 'key_robot' }

    factory :validation_property do
      name  { 'Verification behaviour' }
      value { 'SourceDestBeds' }
      key   { 'verification_behaviour' }
    end

    factory :generation_property do
      name  { 'Generation behaviour' }
      value { 'Tecan' }
      key   { 'generation_behaviour' }
    end
  end
end
