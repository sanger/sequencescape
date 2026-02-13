# frozen_string_literal: true

# Privileges granted to any logged in users
class Ability::BaseUser
  include CanCan::Ability

  attr_reader :user

  def initialize(user)
    @user = user
    grant_privileges
  end

  private

  def grant_privileges # rubocop:todo Metrics/AbcSize, Metrics/MethodLength
    Rails.logger.debug { 'Granting BaseUser privileges' }

    can :delete, Comment, { user_id: user.id }
    can :create, Comment, commentable_type: %w[Study Sample], commentable: { owners: { id: user.id } }

    # There isn't really much reason to stop users seeing this
    can :read, Delayed::Job
    can :read, Labware
    can %i[read create], Project

    # Basic users can only create submissions using projects they own.
    can :create_submission, Project, owners: { id: user.id }
    can :read, ReferenceGenome
    can :read, Robot
    can %i[update release accession], Sample, owners: { id: user.id }
    can %i[read create], Study
    can :print_asset_group_labels, Study, owners: { id: user.id }
    can :print_asset_group_labels, Study, managers: { id: user.id }
    can %i[read create update edit download_scrna_core_pooling_plan], Submission
    can :read, [TagGroup, TagLayoutTemplate, TagSet]
    can %i[read update print_swipecard], User, { id: user.id }
    can %i[projects study_reports], User

    grant_advanced_batch_operation_privileges
  end

  # Before this was granted to anyone, unless they
  # were an owner of anything, in which case they also
  # had to be a manager, possibly of something
  # This is silly. So we'll just grant them to everyone
  # now, but pop them in a separate section so its easy to
  # revisit
  def grant_advanced_batch_operation_privileges
    can :edit, Batch
    can :print, Batch
    can :sample_prep_worksheet, Batch
    can :verify, Batch
  end
end
