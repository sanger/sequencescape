# frozen_string_literal: true

require 'rails_helper'

describe Robot do
  describe '::with_verification_behaviour' do
    let(:robot_standard) { create(:robot, name: 'robot 1') }
    let(:robot_with_verification_behaviour) { create(:robot_with_verification_behaviour, name: 'robot 2') }

    setup do
      robot_standard
      robot_with_verification_behaviour
    end

    it 'returns only the expected scope' do
      expect(described_class.with_verification_behaviour).to eq [robot_with_verification_behaviour]
    end
  end

  describe '#verification_behaviour' do
    let(:robot_with_verification_behaviour) do
      create(:robot_with_verification_behaviour, name: 'robot 2', verification_behaviour_value: 'Hamilton')
    end

    it 'returns the appropriate class' do
      expect(robot_with_verification_behaviour.verification_behaviour).to be_a(Hamilton)
    end
  end
end
