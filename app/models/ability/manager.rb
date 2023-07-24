# frozen_string_literal: true

# Privileges granted to users with the manager role
# Note: This role should be by association only (ie. You can 'manage' a particular)
# study, yet also grants global privileges. This is especially problematic, as
# you automatically becoem a manager of any project you create, and anyone can create
# a project
class Ability::Manager
  include CanCan::Ability

  # These should be extracted to a different class
  prepend Ability::Shared::PowerUser

  attr_reader :user

  def initialize(user)
    @user = user
    grant_privileges
  end

  private

  def grant_privileges # rubocop:todo Metrics/AbcSize
    Rails.logger.debug { 'Granting Manager privileges' }

    can(:edit, Labware) { |lw| !lw.is_a?(PlateTemplate) }
    cannot :edit, PlateTemplate

    # Can update and edit projects they manage
    can :update, Project, managers: { id: user.id }

    # Slight difference here from before. Previously managers
    # could use any study/project until they were owner,
    # manager or follows of a project, as which point they were
    # limited to that one. Now we always limit. The alternative
    # is far too permissive.
    can :create_submission, Project, managers: { id: user.id }

    # If a user is a manager, this is the list of studies
    # shown in the dropdown.
    can :request_additional_with, Study, managers: { id: user.id }

    # Slight changes to behaviour, selects most permissive route
    can :unlink_sample, Study, managers: { id: user.id }
    can :accession, Study, managers: { id: user.id }
    can :link_sample, Study, managers: { id: user.id }

    # Includes ability to add labware to asset group
    can :create, AssetGroup, study: { managers: { id: user.id } }
    can :create, Order, study: { managers: { id: user.id } }
  end
end
