# frozen_string_literal: true

# Originally used to generate an overwhelmingly
# large spec file. Kept primarily for reference
class AbilityAnalysis::SpecGenerator
  attr_reader :ability_analysis

  def initialize(ability_analysis, output: $stdout)
    @ability_analysis = ability_analysis
    @output = output
  end

  delegate :ability, :roles, :sorted_permissions, :abilities_for,
           :user_with_role, to: :ability_analysis

  def generate
    output <<~HEADER
      # frozen_string_literal: true

      require 'cancan/matchers'

      RSpec.describe #{ability} do

        subject(:ability) { described_class.new(user) }

        let(:user) { nil }

    HEADER
    generate_no_user
    output
    generate_basic_user
    output
    roles.each do |role|
      generate_for(role)
      output
    end
    output 'end'
    output
  end

  private

  def output(content = '')
    @output.puts(content)
  end

  def generate_no_user
    output "  context 'when there is no user' do"
    output '    let(:user) { nil }'
    output
    user = nil
    generate_tests(user)
    output '  end'
  end

  def generate_basic_user
    output "  context 'when there is a basic user' do"
    output '    let(:user) { build :user }'
    output
    user = User.new
    generate_tests(user)
    output '  end'
  end

  def generate_for(role)
    output "  context 'when the user has the role \"#{role}\"' do"
    output "    let(:user) { build :user, :with_role, role_name: '#{role}' }"
    generate_authorized_models(role)
    output
    user = user_with_role(role)
    generate_tests(user, role: role)
    output '  end'
  end

  def generate_authorized_models(role)
    AbilityAnalysis::AUTHORIZED_ROLES.fetch(role, []).each do |object|
      output "    let(:authorized_#{object}) { build :#{object}, :with_#{role}, #{role}: user }"
      output "    let(:unauthorized_#{object}) { build :#{object} }"
    end
  end

  def generate_tests(user, role: nil)
    ability = abilities_for(user)
    sorted_permissions.each do |klass, actions|
      output "    # #{klass}"
      actions.each do |action|
        generate_test(ability, action, klass)
        generate_authorized_test(ability, action, klass, role)
      end
      output
    end
  end

  def generate_test(ability, action, klass)
    to_or_not = ability.can?(action, klass.constantize) ? 'to' : 'not_to'
    output "    it { is_expected.#{to_or_not} be_able_to(:#{action}, #{klass}) }"
  end

  def generate_authorized_test(ability, action, klass, role)
    return unless role && AbilityAnalysis::AUTHORIZED_ROLES.fetch(role, []).include?(klass.downcase)

    authorized = klass.constantize.new(roles: [Role.new(name: role.pluralize, users: [ability.user])])
    unauthorized = klass.constantize.new
    auth_to_or_not = ability.can?(action, authorized) ? 'to' : 'not_to'
    output "    it { is_expected.#{auth_to_or_not} be_able_to(:#{action}, authorized_#{klass.downcase}) }"
    unauth_to_or_not = ability.can?(action, unauthorized) ? 'to' : 'not_to'
    output "    it { is_expected.#{unauth_to_or_not} be_able_to(:#{action}, unauthorized_#{klass.downcase}) }"
  end
end
