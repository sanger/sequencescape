####################################################################################################################
# Used in features/listing_by_type
####################################################################################################################
# This user is used when setting up relations to the studies and as the login for the feature.  It isn't actually
# required (as the login step does this) but it's here for clarity should that ever change.
Factory.define(:listing_studies_user, :parent => :user) do |user|
  user.login 'listing_studies_user'
end

# The fairly obvious ones ;)
Factory.define(:study_for_study_list_pending, :parent => :study) do |study|
  study.name  'Study: Pending'
  study.state 'pending'
end
Factory.define(:study_for_study_list_active, :parent => :study) do |study|
  study.name  'Study: Active'
  study.state 'active'
end
Factory.define(:study_for_study_list_inactive, :parent => :study) do |study|
  study.name  'Study: Inactive'
  study.state 'inactive'
end

# These require property definitions to be properly setup
Factory.define(:study_metadata_for_study_list_pending_ethical_approval, :parent => :study_metadata) do |metadata|
  metadata.contains_human_dna     'Yes'
  metadata.contaminated_human_dna 'No'
  metadata.commercially_available 'No'
end
Factory.define(:study_for_study_list_pending_ethical_approval, :parent => :study) do |study|
  study.name               'Study: Pending ethical approval'
  #study.ethically_approved false
  study.after_create do |study|
    study.study_metadata.update_attributes!(Factory.attributes_for(:study_metadata_for_study_list_pending_ethical_approval, :study => study, :faculty_sponsor => study.study_metadata.faculty_sponsor))
    study.save # Required to re-force before_validation event
  end
end

Factory.define(:study_metadata_for_study_list_contaminated_with_human_dna, :parent => :study_metadata) do |metadata|
  metadata.contaminated_human_dna 'Yes'
end
Factory.define(:study_for_study_list_contaminated_with_human_dna, :parent => :study) do |study|
  study.name           'Study: Contaminated with human dna'
  study.after_create do |study|
    study.study_metadata.update_attributes!(Factory.attributes_for(:study_metadata_for_study_list_contaminated_with_human_dna, :study => study, :faculty_sponsor => study.study_metadata.faculty_sponsor))
  end
end

Factory.define(:study_metadata_for_study_list_remove_x_and_autosomes, :parent => :study_metadata) do |metadata|
  metadata.remove_x_and_autosomes 'Yes'
end
Factory.define(:study_for_study_list_remove_x_and_autosomes, :parent => :study) do |study|
  study.name           'Study: Remove x and autosomes'
  study.after_create do |study|
    study.study_metadata.update_attributes!(Factory.attributes_for(:study_metadata_for_study_list_remove_x_and_autosomes, :study => study, :faculty_sponsor => study.study_metadata.faculty_sponsor))
  end
end

# These have to build a user list
Factory.define(:study_for_study_list_managed_active, :parent => :study) do |study|
  study.name  'Study: Managed & active'
  study.state 'active'

  study.after_create do |study|
    user = User.find_by_login('listing_studies_user') or Factory(:listing_studies_user)
    user.has_role('manager', study)
  end
end
Factory.define(:study_for_study_list_managed_inactive, :parent => :study) do |study|
  study.name  'Study: Managed & inactive'
  study.state 'inactive'

  study.after_create do |study|
    user = User.find_by_login('listing_studies_user') or Factory(:listing_studies_user)
    user.has_role('manager', study)
  end
end
Factory.define(:study_for_study_list_followed, :parent => :study) do |study|
  study.name 'Study: Followed'

  study.after_create do |study|
    user = User.find_by_login('listing_studies_user') or Factory(:listing_studies_user)
    user.has_role('follower', study)
  end
end
Factory.define(:study_for_study_list_collaborations, :parent => :study) do |study|
  study.name 'Study: Collaborations'

  study.after_create do |study|
    user = User.find_by_login('listing_studies_user') or Factory(:listing_studies_user)
    user.has_role('collaborator', study)
  end
end
Factory.define(:study_for_study_list_interesting, :parent => :study) do |study|
  study.name 'Study: Interesting'

  # NOTE: Doesn't appear to matter what role the user has!
  study.after_create do |study|
    user = User.find_by_login('listing_studies_user') or Factory(:listing_studies_user)
    user.has_role('follower', study)
  end
end
