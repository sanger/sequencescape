# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::StudyIo do
  subject do
    create(
      :study,
      ethically_approved: true,
      study_metadata_attributes: {
        faculty_sponsor: create(:faculty_sponsor, name: 'John Smith'),
        data_release_strategy: 'open',
        data_release_timing: 'standard',
        reference_genome: reference_genome,
        array_express_accession_number: 'AE111',
        ega_policy_accession_number: 'EGA222',
        ega_dac_accession_number: 'DAC333',
        program: create(:program, name: 'General'),
        contaminated_human_data_access_group: 'contaminated human data access group test'
      }
    )
  end

  let(:reference_genome) { create(:reference_genome) }

  let!(:manager) { create(:manager, authorizable: subject) }
  let!(:manager2) { create(:manager, authorizable: subject) }

  let(:expected_json) do
    {
      'uuid' => subject.uuid,
      'id' => subject.id,
      'name' => subject.name,
      'ethically_approved' => true,
      'reference_genome' => reference_genome.name,
      'study_type' => 'Not specified',
      'abstract' => nil,
      'sac_sponsor' => 'John Smith',
      'abbreviation' => 'WTCCC',
      'accession_number' => nil,
      'description' => 'Some study on something',
      'state' => 'active',
      'contaminated_human_dna' => 'No',
      'contains_human_dna' => 'No',
      'alignments_in_bam' => true,
      'remove_x_and_autosomes' => false,
      'separate_y_chromosome_data' => false,
      'data_release_sort_of_study' => 'genomic sequencing',
      'data_release_strategy' => 'open',
      'data_release_timing' => 'standard',
      'study_visibility' => 'Hold',
      'array_express_accession_number' => 'AE111',
      'ega_policy_accession_number' => 'EGA222',
      'ega_dac_accession_number' => 'DAC333',
      'data_access_group' => 'something',
      's3_email_list' => 'aa1@sanger.ac.uk;aa2@sanger.ac.uk',
      'data_deletion_period' => '3 months',
      'contaminated_human_data_access_group' => 'contaminated human data access group test',
      'programme' => 'General',
      'manager' => [
        { login: manager.login, email: manager.email, name: manager.name },
        { login: manager2.login, email: manager2.email, name: manager2.name }
      ]
    }
  end

  it_behaves_like('an IO object')
end
