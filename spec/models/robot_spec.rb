# frozen_string_literal: true

require 'rails_helper'

describe Robot do
  describe '::with_verification_behaviour' do
    let(:robot_standard) { create(:robot, name: 'robot 1') }
    let(:robot_with_verification_behaviour) { create(:robot_with_verification_behaviour, name: 'robot 2') }

    before do
      robot_standard
      robot_with_verification_behaviour
    end

    it 'returns only the expected scope' do
      expect(described_class.with_verification_behaviour).to eq [robot_with_verification_behaviour]
    end
  end

  describe '#verification_behaviour' do
    let(:robot) do
      create(:robot_with_verification_behaviour, name: 'robot 2', verification_behaviour_value: 'Hamilton')
    end

    it 'returns the appropriate class' do
      expect(robot.verification_behaviour).to be_a(Robot::Verification::SourceDestControlBeds)
    end
  end

  describe '#generation_behaviour' do
    let(:robot) { create(:robot_with_generation_behaviour, name: 'robot 2', generation_behaviour_value: 'Hamilton') }
    let(:generator_id) { robot.generation_behaviour_properties.first.id }

    it 'returns the appropriate class' do
      expect(robot.generation_behaviour(generator_id)).to eq(Robot::Generator::Hamilton)
    end
  end
end
