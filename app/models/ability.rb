# frozen_string_literal: true

# Controls authorization (the ability to do something) based on the current user
# and driven mostly by assigned roles.
# @note API V1 abilities predate this file and are managed separately in {Core::Abilities}
# Powered by CanCanCan https://rdoc.info/github/CanCanCommunity/cancancan
class Ability
  include CanCan::Ability

  attr_reader :user

  ROLE_CLASSES = {
    'administrator' => Ability::Administrator,
    'lab_manager' => Ability::LabManager,
    'manager' => Ability::Manager,
    'slf_gel' => Ability::SampleManagementGel,
    'slf_manager' => Ability::SampleManagementManager,
    'qa_manager' => Ability::QaManager,
    'data_access_coordinator' => Ability::DataAccessCoordinator
  }.freeze

  def initialize(user)
    @user = user
    Rails.logger.debug { "Auth: #{user}, roles: #{user.try(:role_names)}" }

    # Define abilities for the passed in user here. For example:
    #
    #   user ||= User.new # guest user (not logged in)
    #   if user.admin?
    #     can :manage, :all
    #   else
    #     can :read, :all
    #   end
    #
    # The first argument to `can` is the action you are giving the user
    # permission to do.
    # If you pass :manage it will apply to every action. Other common actions
    # here are :read, :create, :update and :destroy.
    # JG: While these don't *have* to correspond to controller actions, it
    #     is easier to handle if they do. (Where appropriate of course)
    #
    # The second argument is the resource the user can perform the action on.
    # If you pass :all it will apply to every resource. Otherwise pass a Ruby
    # class of the resource.
    #
    # The third argument is an optional hash of conditions to further filter the
    # objects.
    # For example, here the user can only update published articles.
    #
    #   can :update, Article, :published => true
    #
    # See the wiki for details:
    # https://github.com/CanCanCommunity/cancancan/wiki/Defining-Abilities

    # Privileges granted even if you aren't
    # logged in.
    grant_global_privileges

    # Only grant basic privileges if the user isn't logged in
    # See {AuthenticatedSystem lib/authenticated_system} for current_user
    # handling.
    # @note I haven't worked out why we use a symbol here, rather than false.
    # rubocop:disable Lint/BooleanSymbol
    return if user.nil? || user == :false

    # rubocop:enable Lint/BooleanSymbol

    # Privileges granted to any logged in users
    grant_basic_privileges

    user.role_names.each do |role|
      role_class = ROLE_CLASSES[role]
      merge(role_class.new(user)) unless role_class.nil?
    end

    ## Aliases
    # @note Alias need to be set up at the *end* of this method, as otherwise
    #       they get blown away when we merge in the other roles

    # Submissions controller uses these actions as part of submission creation
    # It doesn't appear that CanCanCan lets us scope an alias to a particular
    # resource, so these aliases *will* apply globally.
    alias_action :order_fields, :study_assets, to: :create
  end

  # Global privileges are those granted
  # EVEN IF THE USER IS NOT LOGGED IN
  def grant_global_privileges
  end

  # Permissions granted to all users following
  # authentication
  def grant_basic_privileges
    merge(Ability::BaseUser.new(user))
  end
end
