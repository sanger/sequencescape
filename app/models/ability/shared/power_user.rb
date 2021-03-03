# frozen_string_literal: true

# Prepend to an ability class to include Power User privileges
# These are the privileges shared by administrators and managers
module Ability::Shared::PowerUser
  def grant_privileges
    super
    Rails.logger.debug { 'Granting PowerUser privileges' }
    # Admin link will appear
    can :administer, Sequencescape
    can :convert_to_tube, Plate
    can :close, Receptacle
    can :manage, Receptacle
    can :cancel, Request
    can :copy, Request
    can :change_decision, Request
    can :create_additional, Request
    can :update, Sample
    can :release, Sample
    can :accession, Sample
    can %i[activate deactivate], Study
    can %i[create update], Study
    can :create, SampleManifest
    can :create, Supplier
    can :create, Comment
  end
end
