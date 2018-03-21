# frozen_string_literal: true

FactoryGirl.define do
  factory :study_metadata, class: Study::Metadata do
    faculty_sponsor
    study_description           'Some study on something'
    program                     { Program.find_or_create_by(name: 'General') }
    contaminated_human_dna      'No'
    contains_human_dna          'No'
    commercially_available      'No'
    # Study type is implemented poorly. But I'm in the middle of the rails 4
    # upgrade at the moment, so I need to get things working before I change them.
    study_type                  { StudyType.find_or_create_by(name: 'Not specified') }
    # This is probably a bit grim as well
    data_release_study_type     { DataReleaseStudyType.find_or_create_by(name: 'genomic sequencing') }
    reference_genome
    data_release_strategy       'open'
    study_name_abbreviation     'WTCCC'
    data_access_group           'something'
    s3_email_list               'aa1@sanger.ac.uk;aa2@sanger.ac.uk'
    data_deletion_period        '3 months'

    # These require property definitions to be properly setup
    factory :study_metadata_for_study_list_pending_ethical_approval do
      contains_human_dna     'Yes'
      contaminated_human_dna 'No'
      commercially_available 'No'
    end

    factory :study_metadata_for_study_list_contaminated_with_human_dna do
      contaminated_human_dna 'Yes'
    end

    factory :study_metadata_for_study_list_remove_x_and_autosomes do
      remove_x_and_autosomes 'Yes'
    end
  end
end
