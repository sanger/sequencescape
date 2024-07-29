# frozen_string_literal: true

# Privileges granted users with the administrator role
class Ability::Administrator
  include CanCan::Ability

  prepend Ability::Shared::SuperUser
  prepend Ability::Shared::PowerUser
  prepend Ability::Shared::TagCreationUser
  prepend Ability::Shared::SampleManagementUser

  attr_reader :user

  def initialize(user)
    @user = user
    grant_privileges
  end

  private

  # rubocop:todo Metrics/MethodLength
  def grant_privileges # rubocop:todo Metrics/AbcSize
    Rails.logger.debug { 'Granting Administrator privileges' }

    # Labware
    can %i[edit rename change_purpose edit_retention_instruction], Labware

    # Requests
    can :update, Request

    # Lets the user request additional sequencing/libraries
    # under a different study/project than the original
    can :edit_additional, Request

    # For old pipelines, removes QC events
    can :reset_qc_information, Request

    # If a sample has been released to the ENA, we need
    # to be careful about editing it.
    can :update_released, Sample

    # Administer covers update of the studies via the
    # admin/studies controller. It mostly adds the ability
    # to activate/deactivate a study and change ethical approval
    # or data-release fields
    can :administer, Study

    # If the user is an administrator show all studies.
    can :request_additional_with, Study
    can :unlink_sample, Study
    can :link_sample, Study
    can :accession, Study
    can %i[grant_role remove_role], Study

    # Projects
    # Administer covers update of the projects via the
    # admin/projects controller. It mostly adds the ability
    # to disable enforced validation, and add financial approval
    can :administer, Project

    # Manage is actually more powerful than administer.
    can :manage, Project

    # Previously granted to managers who weren't specifically managers of a
    # particular study
    can :create_submission, Project

    can :rollback, Batch

    can :delete, Comment

    can :manage, BarcodePrinter
    can :create, [Purpose, PlatePurpose]
    can :manage, Program
    can :manage, [BaitLibrary, BaitLibrary::Supplier, BaitLibraryType]
    can :manage, PrimerPanel

    can :manage, Role
    can :delete, Document

    can :manage, AssetGroup
    can :create, Order

    can :print_asset_group_labels, Study

    # Edit and delete submissions
    can :manage, Submission
    can :cancel, Submission
  end
  # rubocop:enable Metrics/MethodLength
end
