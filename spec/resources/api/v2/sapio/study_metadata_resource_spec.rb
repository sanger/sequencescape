# frozen_string_literal: true

require 'rails_helper'
require './app/resources/api/v2/sapio/study_metadata_resource'

RSpec.describe Api::V2::Sapio::StudyMetadataResource, type: :resource do
  subject { described_class.new(resource_model, {}) }

  let(:resource_model) { build_stubbed(:study_metadata) }

  # Mutability
  it { expect(described_class.mutable?).to be(false) }

  # Model Name
  it { is_expected.to have_model_name 'Study::Metadata' }

  # Attributes
  it { is_expected.to have_readwrite_attribute :old_sac_sponsor }
  it { is_expected.to have_readwrite_attribute :study_description }
  it { is_expected.to have_readwrite_attribute :contaminated_human_dna }
  it { is_expected.to have_readwrite_attribute :study_project_id }
  it { is_expected.to have_readwrite_attribute :study_abstract }
  it { is_expected.to have_readwrite_attribute :study_study_title }
  it { is_expected.to have_readwrite_attribute :study_ebi_accession_number }
  it { is_expected.to have_readwrite_attribute :study_sra_hold }
  it { is_expected.to have_readwrite_attribute :contains_human_dna }
  it { is_expected.to have_readwrite_attribute :study_name_abbreviation }
  it { is_expected.to have_readwrite_attribute :reference_genome_old }
  it { is_expected.to have_readwrite_attribute :data_release_strategy }
  it { is_expected.to have_readwrite_attribute :data_release_standard_agreement }
  it { is_expected.to have_readwrite_attribute :data_release_timing }
  it { is_expected.to have_readwrite_attribute :data_release_delay_reason }
  it { is_expected.to have_readwrite_attribute :data_release_delay_other_comment }
  it { is_expected.to have_readwrite_attribute :data_release_delay_period }
  it { is_expected.to have_readwrite_attribute :data_release_delay_approval }
  it { is_expected.to have_readwrite_attribute :data_release_delay_reason_comment }
  it { is_expected.to have_readwrite_attribute :data_release_prevention_reason }
  it { is_expected.to have_readwrite_attribute :data_release_prevention_approval }
  it { is_expected.to have_readwrite_attribute :data_release_prevention_reason_comment }
  it { is_expected.to have_readwrite_attribute :snp_study_id }
  it { is_expected.to have_readwrite_attribute :snp_parent_study_id }
  it { is_expected.to have_readwrite_attribute :bam }
  it { is_expected.to have_readwrite_attribute :study_type_id }
  it { is_expected.to have_readwrite_attribute :study_type_name }
  it { is_expected.to have_readwrite_attribute :data_release_study_type_id }
  it { is_expected.to have_readwrite_attribute :data_release_study_type_name }
  it { is_expected.to have_readwrite_attribute :reference_genome_id }
  it { is_expected.to have_readwrite_attribute :reference_genome_name }
  it { is_expected.to have_readwrite_attribute :array_express_accession_number }
  it { is_expected.to have_readwrite_attribute :dac_policy }
  it { is_expected.to have_readwrite_attribute :ega_policy_accession_number }
  it { is_expected.to have_readwrite_attribute :ega_dac_accession_number }
  it { is_expected.to have_readwrite_attribute :commercially_available }
  it { is_expected.to have_readwrite_attribute :number_of_gigabases_per_sample }
  it { is_expected.to have_readwrite_attribute :hmdmc_approval_number }
  it { is_expected.to have_readwrite_attribute :created_at }
  it { is_expected.to have_readwrite_attribute :updated_at }
  it { is_expected.to have_readwrite_attribute :remove_x_and_autosomes }
  it { is_expected.to have_readwrite_attribute :dac_policy_title }
  it { is_expected.to have_readwrite_attribute :separate_y_chromosome_data }
  it { is_expected.to have_readwrite_attribute :data_access_group }
  it { is_expected.to have_readwrite_attribute :prelim_id }
  it { is_expected.to have_readwrite_attribute :program_id }
  it { is_expected.to have_readwrite_attribute :program_name }
  it { is_expected.to have_readwrite_attribute :s3_email_list }
  it { is_expected.to have_readwrite_attribute :data_deletion_period }
  it { is_expected.to have_readwrite_attribute :contaminated_human_data_access_group }
  it { is_expected.to have_readwrite_attribute :data_release_prevention_other_comment }
  it { is_expected.to have_readwrite_attribute :ebi_library_strategy }
  it { is_expected.to have_readwrite_attribute :ebi_library_source }
  it { is_expected.to have_readwrite_attribute :ebi_library_selection }
  it { is_expected.to have_readwrite_attribute :data_release_timing_publication_comment }
  it { is_expected.to have_readwrite_attribute :data_share_in_preprint }

  # Relationships
  it { is_expected.to have_a_writable_has_one(:study_type).with_class_name('StudyType') }
  it { is_expected.to have_a_writable_has_one(:data_release_study_type).with_class_name('DataReleaseStudyType') }
  it { is_expected.to have_a_writable_has_one(:reference_genome).with_class_name('ReferenceGenome') }
  it { is_expected.to have_a_readonly_has_one(:faculty_sponsor).with_class_name('FacultySponsor') }
  it { is_expected.to have_a_writable_has_one(:program).with_class_name('Program') }
end
