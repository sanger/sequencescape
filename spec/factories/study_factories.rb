# frozen_string_literal: true

####################################################################################################################
# Used in features/listing_by_type
####################################################################################################################
# This user is used when setting up relations to the studies and as the login for the feature.  It isn't actually
# required (as the login step does this) but it's here for clarity should that ever change.
FactoryBot.define do
  factory :study do
    name { generate(:study_name) }
    user
    blocked { false }
    state { 'active' }
    enforce_data_release { false }
    enforce_accessioning { false }
    study_metadata

    transient do
      # Options to set in the study metadata
      metadata_options { {} }
    end

    after(:build) do |study|
      study.study_metadata.update!(
        ebi_library_strategy: 'WGS',
        ebi_library_source: 'GENOMIC',
        ebi_library_selection: 'PCR'
      )
    end

    after(:create) do |study, evaluator|
      # Set any metadata options passed in
      study.study_metadata.update!(evaluator.metadata_options)
    end

    # These have to build a user list
    factory(:study_with_manager) { after(:build) { |study| create(:manager, authorizable: study) } }
  end

  factory(:managed_study, parent: :study) do
    transient { accession_number { nil } }

    sequence(:name) { |n| "Study#{n}: Manages" }
    state { 'active' }
    enforce_accessioning { true }
    enforce_data_release { true }

    after(:create) do |study, evaluator|
      study.study_metadata.update!(
        data_release_strategy: 'managed',
        study_ebi_accession_number: evaluator.accession_number,
        study_abstract: 'Lorem ipsum dolor sit amet, consectetur adipiscing elit.',
        study_study_title: 'A managed study for testing purposes',
        study_type: create(:study_type)
      )
    end
  end

  factory(:open_study, parent: :study) do
    transient { accession_number { nil } }
    transient { data_release_timing { 'standard' } }

    sequence(:name) { |n| "Study#{n}: Open" }
    state { 'active' }
    enforce_accessioning { true }
    enforce_data_release { true }

    after(:create) do |study, evaluator|
      study.study_metadata.update!(
        data_release_strategy: 'open',
        data_release_timing: evaluator.data_release_timing,
        study_ebi_accession_number: evaluator.accession_number
      )
    end
  end

  factory(:not_app_study, parent: :study) do
    name { 'Study: Never' }
    state { 'active' }
    after(:create) do |study|
      new_field_values = {
        data_release_strategy: 'not applicable',
        data_release_timing: 'never',
        data_release_prevention_reason: 'Protecting IP - DAC approval required',
        data_release_prevention_approval: 'Yes'
      }
      study.study_metadata.update!(new_field_values)
    end
  end

  factory :study_type do
    name { generate(:study_type_name) }
  end

  factory :data_release_study_type do
    name { generate(:data_release_study_type_name) }
  end

  factory(:faculty_sponsor) { name { |_a| generate(:faculty_sponsor_name) } }

  factory :study_for_study_list, parent: :study do
    transient do
      user
      role_name { 'manager' }
    end

    after(:build) { |study, evaluator| evaluator.user.grant_role(evaluator.role_name, study) }

    # The fairly obvious ones ;)
    factory(:study_for_study_list_pending) do
      name { 'Study: Pending' }
      state { 'pending' }
    end

    factory(:study_for_study_list_active) do
      name { 'Study: Active' }
      state { 'active' }
    end

    factory(:study_for_study_list_inactive) do
      name { 'Study: Inactive' }
      state { 'inactive' }
    end

    factory(:study_for_study_list_pending_ethical_approval) do
      name { 'Study: Pending ethical approval' }
      ethically_approved { false }
      study_metadata_attributes { FactoryBot.attributes_for(:study_metadata_for_study_list_pending_ethical_approval) }
    end

    factory(:study_for_study_list_remove_x_and_autosomes) do
      name { 'Study: Remove x and autosomes' }
      study_metadata_attributes { attributes_for(:study_metadata_for_study_list_remove_x_and_autosomes) }
    end
    factory(:study_for_study_list_contaminated_with_human_dna) do
      name { 'Study: Contaminated with human dna' }
      study_metadata_attributes { attributes_for(:study_metadata_for_study_list_contaminated_with_human_dna) }
    end

    # These have to build a user list
    factory(:study_for_study_list_managed_active) do
      name { 'Study: Managed & active' }
      state { 'active' }
    end

    factory(:study_for_study_list_managed_inactive) do
      name { 'Study: Managed & inactive' }
      state { 'inactive' }
    end

    factory(:study_for_study_list_followed) do
      name { 'Study: Followed' }

      transient { role_name { 'follower' } }
    end

    factory(:study_for_study_list_collaborations) do
      name { 'Study: Collaborations' }
      transient { role_name { 'collaborator' } }
    end

    factory(:study_for_study_list_interesting) do
      name { 'Study: Interesting' }
      transient { role_name { 'follower' } }
    end
  end
end
