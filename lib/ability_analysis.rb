# frozen_string_literal: true

# Tools to assist with analysing permissions
class AbilityAnalysis
  attr_reader :permissions, :roles, :ability

  ALIAS = {
    update: [:edit],
    show: [:read],
    index: [:read],
    manage: %i[create edit read delete]
  }.freeze

  # Roles associated with an authorizable
  AUTHORIZED_ROLES = {
    'manager' => %w[project study],
    'follower' => %w[project study],
    'owner' => %w[project sample study]
  }.freeze

  # These were pulled directly out of Sequencescape by finding
  # can\?[ \(]:\w+, *[\w@_]+ and then were re-jigged semi-manually
  BASE_ABILITIES = {
    'AssetGroup' => %i[create edit read delete],
    'BaitLibrary' => %i[create edit read delete],
    'BarcodePrinter' => %i[create edit read delete],
    'Batch' => [:rollback],
    'Comment' => %i[create delete],
    'CustomText' => %i[create edit read delete],
    'Delayed::Job' => [:read],
    'Document' => [:delete],
    'FacultySponsor' => %i[create edit read delete],
    'GelsController' => %i[create edit read delete],
    'Labware' => %i[rename change_purpose edit],
    'Order' => [:create],
    'Plate' => [:convert_to_tube],
    'PlateTemplate' => [:read],
    'PrimerPanel' => %i[create edit read delete],
    'Program' => %i[create edit read delete],
    'Project' => %i[administer edit create],
    'Purpose' => %i[create edit read delete],
    'QcDecision' => [:create],
    'Receptacle' => %i[edit close],
    'ReferenceGenome' => %i[create edit read delete],
    'Request' => %i[create_additional copy cancel change_priority see_previously_failed edit_additional reset_qc_information edit change_decision],
    'Robot' => %i[create edit read delete],
    'Role' => %i[create administer edit read delete],
    'Sample' => %i[edit release accession],
    'SampleLogisticsController' => [:read],
    'SampleManifest' => [:create],
    'Sequencescape' => [:administer],
    'Study' => %i[administer unlink_sample link_sample edit create activate deactivate print_asset_group_labels],
    'Submission' => %i[create read edit delete change_priority],
    'Supplier' => [:create],
    'TagGroup' => [:create],
    'TagLayoutTemplate' => [:create],
    'User' => [:administer]
  }.freeze

  def initialize(permissions: BASE_ABILITIES, roles: Role.keys, ability: Ability, output: $stdout)
    @roles = roles
    @permissions = permissions.deep_dup
    @ability = ability
    populate_permissions
    @permissions.freeze
    @output = output
  end

  def generate_spec(output = $stdout)
    AbilityAnalysis::SpecGenerator.new(self, output: output).generate
  end

  def abilities_for(user)
    ability.new(user)
  end

  def sorted_permissions
    permissions.sort_by(&:first)
  end

  def user_with_role(role_name)
    User.new(roles: [Role.new(name: role_name)])
  end

  private

  def translate(action)
    ALIAS[action] || [action]
  end

  def extract_permissions(ability)
    ability_permissions = ability.permissions.values.reduce(&:merge)

    ability_permissions.each do |action, models|
      models.each_key do |model|
        permissions[model] ||= []
        permissions[model].concat(translate(action))
        permissions[model].uniq!
      end
    end
  end

  def populate_permissions
    roles.each do |role_name|
      user = user_with_role(role_name)
      extract_permissions(abilities_for(user))
    end
  end
end

require_relative 'ability_analysis/spec_generator'
