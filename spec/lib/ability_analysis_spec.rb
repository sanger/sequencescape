# frozen_string_literal: true

# require 'rails_helper'
require 'spec_helper'

RSpec.describe AbilityAnalysis do
  subject(:ability_analysis) { described_class.new(roles:, ability:, permissions:) }

  let(:roles) { %w[role_a role_b] }
  let(:permissions) { { 'Study' => %i[edit read], 'Project' => %i[edit read] } }

  let(:ability) do
    Class.new do
      include CanCan::Ability

      def initialize(user)
        @user = user
        can :read, Sample
        return if user.nil?

        can :edit, Study, { active: true }
        can :read, Study
        can :edit, Project
      end

      def inspect
        "<:ability:#{object_id} permissions: #{permissions}, user: #{@user}>"
      end
    end
  end

  describe '#permission_matrix' do
    let(:expected_matrix) do
      [
        ['Project', [[:edit, [false, true, true, true]], [:read, [false, false, false, false]]]],
        ['Sample', [[:read, [true, true, true, true]]]],
        [
          'Study',
          [[:edit, [false, { active: true }, { active: true }, { active: true }]], [:read, [false, true, true, true]]]
        ]
      ]
    end

    it 'returns a description of the permissions' do
      expect(ability_analysis.permission_matrix).to eq expected_matrix
    end
  end

  describe '#all_roles' do
    let(:expected_roles) { ['Logged Out', 'Basic User', 'role_a', 'role_b'] }

    it 'returns a description of the roles' do
      expect(ability_analysis.all_roles).to eq expected_roles
    end
  end
end
