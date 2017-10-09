# This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and authorship of this file.
# Copyright (C) 2007-2011,2012,2013,2016 Genome Research Ltd.
####################################################################################################################
# Used in features/listing_by_type
####################################################################################################################
# This user is used when setting up relations to the studies and as the login for the feature.  It isn't actually
# required (as the login step does this) but it's here for clarity should that ever change.
FactoryGirl.define do
  factory :study do
    name { generate :study_name }
    user
    blocked              false
    state                'active'
    enforce_data_release false
    enforce_accessioning false
    reference_genome     { ReferenceGenome.find_by(name: '') }
    study_metadata

    # These have to build a user list
    factory(:study_with_manager) do
      after(:build) do |study|
        create(:manager, authorizable: study)
      end
    end
  end

  factory(:managed_study, parent: :study) do
    transient do
      accession_number nil
    end

    sequence(:name) { |n| "Study#{n}: Manages" }
    state 'active'

    after(:create) do |study, evaluator|
      study.study_metadata.update_attributes!(data_release_strategy: 'managed', study_ebi_accession_number: evaluator.accession_number)
    end
  end

  factory(:open_study, parent: :study) do
    transient do
      accession_number nil
    end

    sequence(:name) { |n| "Study#{n}: Open" }
    state 'active'

    after(:create) do |study, evaluator|
      study.study_metadata.update_attributes!(data_release_strategy: 'open', study_ebi_accession_number: evaluator.accession_number)
    end
  end

  factory(:not_app_study, parent: :study) do
    name 'Study: Never'
    state 'active'
    after(:create) do |study|
      study.study_metadata.update_attributes!(data_release_strategy: 'not applicable')
    end
  end

  # These require property definitions to be properly setup
  factory(:study_metadata_for_study_list_pending_ethical_approval, parent: :study_metadata) do
    contains_human_dna     'Yes'
    contaminated_human_dna 'No'
    commercially_available 'No'
  end

  factory(:study_metadata_for_study_list_contaminated_with_human_dna, parent: :study_metadata) do
    contaminated_human_dna 'Yes'
  end

  factory(:study_metadata_for_study_list_remove_x_and_autosomes, parent: :study_metadata) do
    remove_x_and_autosomes 'Yes'
  end

  factory :study_for_study_list, parent: :study do
    transient do
      user
      role_name 'manager'
    end

    after(:build) do |study, evaluator|
      evaluator.user.has_role(evaluator.role_name, study)
    end

        # The fairly obvious ones ;)
    factory(:study_for_study_list_pending) do
      name  'Study: Pending'
      state 'pending'
    end

    factory(:study_for_study_list_active) do
      name  'Study: Active'
      state 'active'
    end

    factory(:study_for_study_list_inactive) do
      name  'Study: Inactive'
      state 'inactive'
    end


    factory(:study_for_study_list_pending_ethical_approval) do
      name               'Study: Pending ethical approval'
      ethically_approved false
      study_metadata_attributes { FactoryGirl.attributes_for :study_metadata_for_study_list_pending_ethical_approval }
    end

    factory(:study_for_study_list_remove_x_and_autosomes) do
      name 'Study: Remove x and autosomes'
      study_metadata_attributes { attributes_for(:study_metadata_for_study_list_remove_x_and_autosomes) }
    end
    factory(:study_for_study_list_contaminated_with_human_dna) do
      name 'Study: Contaminated with human dna'
      study_metadata_attributes { attributes_for(:study_metadata_for_study_list_contaminated_with_human_dna) }
    end

    # These have to build a user list
    factory(:study_for_study_list_managed_active) do
      name  'Study: Managed & active'
      state 'active'
    end

    factory(:study_for_study_list_managed_inactive) do
      name  'Study: Managed & inactive'
      state 'inactive'
    end

    factory(:study_for_study_list_followed) do
      name 'Study: Followed'

      transient { role_name 'follower' }
    end

    factory(:study_for_study_list_collaborations) do
      name 'Study: Collaborations'
      transient { role_name 'collaborator' }
    end

    factory(:study_for_study_list_interesting) do
      name 'Study: Interesting'
      transient { role_name 'follower' }
    end
  end
end
