# frozen_string_literal: true

# Tools to assist with analysing permissions
class AbilityAnalysis
  attr_reader :permissions, :roles, :ability

  UserStub = Struct.new(:id, :role_names)

  ALIAS = { update: [:edit], show: [:read], index: [:read], manage: %i[create edit read delete] }.freeze

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
    'Request' => %i[
      create_additional
      copy
      cancel
      change_priority
      see_previously_failed
      edit_additional
      reset_qc_information
      edit
      change_decision
    ],
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
    # NOTE: TagSet is missing from this list, not sure if this was intentional or not
    'User' => [:administer]
  }.freeze

  def initialize(permissions: BASE_ABILITIES, roles: Role.keys, ability: Ability)
    @roles = roles
    @permissions = permissions.deep_dup
    @ability = ability
    populate_permissions
    @permissions.freeze
  end

  def generate_spec(output = $stdout)
    AbilityAnalysis::SpecGenerator.new(self, output:).generate
  end

  def abilities_for(user)
    ability.new(user)
  end

  # Returns an array of arrays in the format:
  # [[Model, [:permissions]]]
  def sorted_permissions
    permissions.sort_by(&:first)
  end

  def all_roles
    ['Logged Out', 'Basic User', *roles]
  end

  #
  # Returns a matrix of permission in the format
  # [ ModelClass, [
  #  [:action, [*permissions_for_each_role]]
  # ]]
  #
  # @return [Array] Nested array of each model and their permissions
  #
  def permission_matrix
    abilities = [abilities_for(nil), abilities_for(user_with_roles), *roles.map { |role| ability_for_role(role) }]
    sorted_permissions.map do |model, actions|
      [model, actions.map { |action| [action, abilities.map { |ability| check_ability?(ability, action, model) }] }]
    end
  end

  def user_with_roles(*role_names)
    UserStub.new('user_id', role_names)
  end

  #
  # Returns an {Ability} for a user with a role named role_name
  #
  # @param role_name [String] The name of a role
  #
  # @return [Ability] An ability covering the role
  #
  def ability_for_role(role_name)
    abilities_for(user_with_roles(role_name))
  end

  private

  # Checks the action for the given ability
  # Indicates if always permissible (true) never permissible (false)
  # or determined by conditions (Hash of conditions)
  #
  # @return [Boolean,Hash] Indicates the level of permissions
  def check_ability?(user_ability, action, model_name)
    model = model_name.constantize
    if user_ability.can? action, model
      begin
        user_ability.model_adapter(model, action).try(:conditions).presence || true
      rescue ArgumentError, CanCan::Error
        # The polymorphic association for comments is causing problems here, but
        # works fine where actually needed.
        { error: 'Rule could not be read automatically' }
      end
    else
      false
    end
  end

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
      user = user_with_roles(role_name)
      extract_permissions(abilities_for(user))
    end
  end
end

require_relative 'ability_analysis/spec_generator'
