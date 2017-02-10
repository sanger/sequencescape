# This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2013 Genome Research Ltd.
####################################################################################################################
# Used in features/listing_by_type
####################################################################################################################
# This user is used when setting up relations to the studies and as the login for the feature.  It isn't actually
# required (as the login step does this) but it's here for clarity should that ever change.
FactoryGirl.define do
  factory(:listing_studies_user, parent: :user) do |_user|
    login 'listing_studies_user'
  end

  # The fairly obvious ones ;)
  factory(:study_for_study_list_pending, parent: :study) do |_study|
    name  'Study: Pending'
    state 'pending'
  end
  factory(:study_for_study_list_active, parent: :study) do |_study|
    name  'Study: Active'
    state 'active'
  end
  factory(:study_for_study_list_inactive, parent: :study) do |_study|
    name  'Study: Inactive'
    state 'inactive'
  end

  factory(:managed_study, parent: :study) do
    name 'Study: Managed'
    state 'active'
    after(:build) do |study|
      study.study_metadata.data_access_group = 'dag'
      study.study_metadata.data_release_strategy = 'managed'
    end
  end
  # These require property definitions to be properly setup
  factory(:study_metadata_for_study_list_pending_ethical_approval, parent: :study_metadata) do |_metadata|
    contains_human_dna     'Yes'
    contaminated_human_dna 'No'
    commercially_available 'No'
  end
  factory(:study_for_study_list_pending_ethical_approval, parent: :study) do |_study|
    name               'Study: Pending ethical approval'
    ethically_approved false
    after(:build) do |study|
      study.study_metadata.update_attributes!(FactoryGirl.attributes_for(:study_metadata_for_study_list_pending_ethical_approval, study: study, faculty_sponsor: study.study_metadata.faculty_sponsor))
      study.save # Required to re-force before_validation event
    end
  end

  factory(:study_metadata_for_study_list_contaminated_with_human_dna, parent: :study_metadata) do |_metadata|
    contaminated_human_dna 'Yes'
  end
  factory(:study_for_study_list_contaminated_with_human_dna, parent: :study) do |_study|
    name 'Study: Contaminated with human dna'
    after(:build) do |study|
      study.study_metadata.update_attributes!(FactoryGirl.attributes_for(:study_metadata_for_study_list_contaminated_with_human_dna, study: study, faculty_sponsor: study.study_metadata.faculty_sponsor))
    end
  end

  factory(:study_metadata_for_study_list_remove_x_and_autosomes, parent: :study_metadata) do |_metadata|
    remove_x_and_autosomes 'Yes'
  end
  factory(:study_for_study_list_remove_x_and_autosomes, parent: :study) do |_study|
    name 'Study: Remove x and autosomes'
    after(:build) do |study|
      study.study_metadata.update_attributes!(FactoryGirl.attributes_for(:study_metadata_for_study_list_remove_x_and_autosomes, study: study, faculty_sponsor: study.study_metadata.faculty_sponsor))
    end
  end

  # These have to build a user list
  factory(:study_for_study_list_managed_active, parent: :study) do |_study|
    name  'Study: Managed & active'
    state 'active'

    after(:build) do |study|
      user = User.find_by(login: 'listing_studies_user') or create(:listing_studies_user)
      user.has_role('manager', study)
    end
  end
  factory(:study_for_study_list_managed_inactive, parent: :study) do |_study|
    name  'Study: Managed & inactive'
    state 'inactive'

    after(:build) do |study|
      user = User.find_by(login: 'listing_studies_user') or create(:listing_studies_user)
      user.has_role('manager', study)
    end
  end
  factory(:study_for_study_list_followed, parent: :study) do |_study|
    name 'Study: Followed'

    after(:build) do |study|
      user = User.find_by(login: 'listing_studies_user') or create(:listing_studies_user)
      user.has_role('follower', study)
    end
  end
  factory(:study_for_study_list_collaborations, parent: :study) do |_study|
    name 'Study: Collaborations'

    after(:build) do |study|
      user = User.find_by(login: 'listing_studies_user') or create(:listing_studies_user)
      user.has_role('collaborator', study)
    end
  end
  factory(:study_for_study_list_interesting, parent: :study) do |_study|
    name 'Study: Interesting'

    # NOTE: Doesn't appear to matter what role the user has!
    after(:build) do |study|
      user = User.find_by(login: 'listing_studies_user') or create(:listing_studies_user)
      user.has_role('follower', study)
    end
  end
end
