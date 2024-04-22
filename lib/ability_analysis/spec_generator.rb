# frozen_string_literal: true

# Originally used to generate an overwhelmingly
# large spec file. Kept primarily for reference
class AbilityAnalysis::SpecGenerator
  attr_reader :ability_analysis

  def initialize(ability_analysis, output: $stdout)
    @ability_analysis = ability_analysis
    @output = output
  end

  delegate :ability, :roles, :sorted_permissions, :abilities_for, :user_with_roles, to: :ability_analysis

  def generate
    output <<~HEADER
      # frozen_string_literal: true

      require 'cancan/matchers'

      RSpec.describe #{ability} do

        subject(:ability) { described_class.new(user) }

        let(:user) { nil }

    HEADER
    generate_permissions_list('global_permissions', sorted_permissions)
    generate_shared_example
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

  def generate_permissions_list(name, permissions_to_list, indent: 2)
    output("let(:#{name}) do", indent:)
    output '{', indent: indent + 2
    list = permissions_to_list.map { |klass, permissions| "#{klass} => %i[#{permissions.join(' ')}]" }.join(",\n")
    output list, indent: indent + 4
    output '}', indent: indent + 2
    output 'end', indent:
  end

  def generate_shared_example
    output
    output <<~SHARED_EXAMPLE, indent: 2
      let(:all_actions) do
        global_permissions.flat_map do |klass, actions|
          actions.map { |action| [klass, action] }
        end
      end

      shared_examples 'it grants only granted_permissions' do
        it 'grants expected permissions', aggregate_failures: true do
          all_actions.each do |klass, action|
            next unless granted_permissions.fetch(klass,[]).include?(action)

            expect(ability).to be_able_to(action, klass)
          end
        end

        it 'does not grant unexpected permissions', aggregate_failures: true do
          all_actions.each do |klass, action|
            next if granted_permissions.fetch(klass,[]).include?(action)

            expect(ability).not_to be_able_to(action, klass)
          end
        end
      end
    SHARED_EXAMPLE
  end

  def output(content = '', indent: 0)
    @output.puts(content.indent(indent))
  end

  def generate_no_user
    output "context 'when there is no user' do", indent: 2
    output 'let(:user) { nil }', indent: 4
    output
    user = nil
    generate_tests(user)
    output 'end', indent: 2
  end

  def generate_basic_user
    output "context 'when there is a basic user' do", indent: 2
    output 'let(:user) { build :user }', indent: 4
    output
    user = User.new
    generate_tests(user)
    output 'end', indent: 2
  end

  def generate_for(role)
    output "context 'when the user has the role \"#{role}\"' do", indent: 2
    output "let(:user) { build :user, :with_role, role_name: '#{role}' }", indent: 4
    generate_authorized_models(role)
    output
    user = user_with_roles(role)
    generate_tests(user, role:)
    output 'end', indent: 2
  end

  def generate_authorized_models(role)
    AbilityAnalysis::AUTHORIZED_ROLES
      .fetch(role, [])
      .each do |object|
        output "    let(:authorized_#{object}) { build :#{object}, :with_#{role}, #{role}: user }"
        output "    let(:unauthorized_#{object}) { build :#{object} }"
      end
  end

  def generate_tests(user, role: nil)
    ability = abilities_for(user)
    granted = permissions_for(ability)
    generate_permissions_list('granted_permissions', granted, indent: 4)
    output
    output "it_behaves_like 'it grants only granted_permissions'", indent: 4
    output
    sorted_permissions.each do |klass, actions|
      next unless AbilityAnalysis::AUTHORIZED_ROLES.fetch(role, []).include?(klass.downcase)

      output "# #{klass}", indent: 4
      actions.each { |action| generate_authorized_test(ability, action, klass, role) }
    end
  end

  def permissions_for(ability)
    sorted_permissions.each_with_object({}) do |(klass, actions), granted|
      actions.each do |action|
        next unless ability.can?(action, klass.constantize)

        granted[klass] ||= []
        granted[klass] << action
      end
    end
  end

  def generate_authorized_test(ability, action, klass, role)
    authorized = klass.constantize.new(roles: [Role.new(name: role.pluralize, users: [ability.user])])
    unauthorized = klass.constantize.new
    auth_to_or_not = ability.can?(action, authorized) ? 'to' : 'not_to'
    output "it { is_expected.#{auth_to_or_not} be_able_to(:#{action}, authorized_#{klass.downcase}) }", indent: 4
    unauth_to_or_not = ability.can?(action, unauthorized) ? 'to' : 'not_to'
    output "it { is_expected.#{unauth_to_or_not} be_able_to(:#{action}, unauthorized_#{klass.downcase}) }", indent: 4
  end
end
