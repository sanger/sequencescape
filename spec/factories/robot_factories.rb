# frozen_string_literal: true

FactoryBot.define do
  factory :robot do
    name { 'myrobot' }
    location { 'lab' }
    transient do
      number_of_sources { 0 }
      number_of_controls { 0 }
      number_of_destinations { 0 }
    end

    after(:create) do |robot, evaluator|
      evaluator.number_of_sources.times do |i|
        bed_number = (i + 1).to_s
        robot.robot_properties << create(
          :robot_property,
          name: "Source #{i + 1}",
          key: "SCRC#{i + 1}",
          value: bed_number
        )
      end

      evaluator.number_of_controls.times do |i|
        bed_number = (evaluator.number_of_sources + i + 1).to_s
        robot.robot_properties << create(
          :robot_property,
          name: "Control #{i + 1}",
          key: "CTRL#{i + 1}",
          value: bed_number
        )
      end

      evaluator.number_of_destinations.times do |i|
        bed_number = (evaluator.number_of_sources + evaluator.number_of_controls + i + 1).to_s
        robot.robot_properties << create(
          :robot_property,
          name: "Destination #{i + 1}",
          key: "DEST#{i + 1}",
          value: bed_number
        )
      end
    end

    factory :robot_with_verification_behaviour do
      transient { verification_behaviour_value { 'Tecan' } }
      robot_properties { build_list :validation_property, 1, value: verification_behaviour_value }
    end

    factory :robot_with_generation_behaviour do
      transient { generation_behaviour_value { 'Tecan' } }
      robot_properties { build_list :generation_property, 1, value: generation_behaviour_value }
    end

    factory :full_robot do
      transient do
        verification_behaviour_value { 'Tecan' }
        generation_behaviour_value { 'Tecan' }
        max_plates_value { 17 }
      end
      robot_properties do
        [
          build(:validation_property, value: verification_behaviour_value),
          build(:generation_property, value: generation_behaviour_value),
          build(:max_plates_property, value: max_plates_value)
        ]
      end

      factory :full_robot_tecan_v2 do
        transient { generation_behaviour_value { 'TecanV2' } }
      end

      factory :hamilton do
        name { 'Alexander' }
        transient do
          verification_behaviour_value { 'SourceDestControlBeds' }
          generation_behaviour_value { 'Hamilton' }
          max_plates_value { 25 }
          number_of_sources { 24 }
          number_of_controls { 1 }
          number_of_destinations { 1 }
        end
      end
    end
  end

  factory :robot_property do
    name { 'myrobot' }
    value { 'lab' }
    key { 'key_robot' }

    factory :validation_property do
      name { 'Verification behaviour' }
      value { 'Tecan' }
      key { 'verification_behaviour' }
    end

    factory :generation_property do
      name { 'Generation behaviour' }
      value { 'Tecan' }
      key { 'generation_behaviour' }
    end

    factory :max_plates_property do
      name { 'Maximum plates' }
      value { 17 }
      key { 'max_plates' }
    end
  end
end
