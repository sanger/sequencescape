# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Submission::ScrnaCoreCdnaPrepFeasibilityCalculator do
  let(:calculator) do
    Class
      .new do
        include Submission::ScrnaCoreCdnaPrepFeasibilityCalculator

        def submission_template_name
          Submission::ScrnaCoreCdnaPrepFeasibilityCalculator::SCRNA_CORE_CDNA_PREP_GEM_X_5P
        end

        def validate_required_headers
          Submission::ScrnaCoreCdnaPrepFeasibilityValidator.new.validate_required_headers
        end

        def group_rows_by_study_and_project
          Submission::ValidationsByTemplateName.new.group_rows_by_study_and_project
        end

        def calculate_number_of_samples_in_smallest_pool(rows)
          Submission::ScrnaCoreCdnaPrepFeasibilityValidator.new.calculate_number_of_samples_in_smallest_pool(rows)
        end

        def headers
          [
            'User Login',
            'Template Name',
            'Project Name',
            'Study Name',
            'Submission name',
            'Barcode',
            'Plate Well',
            'Asset Group Name',
            'Fragment Size From',
            'Fragment Size To',
            'PCR Cycles',
            'Library Type',
            'Bait Library Name',
            'Pre-capture Plex Level',
            'Pre-capture Group',
            'Read Length',
            'Number of lanes',
            'Priority',
            'Primer Panel',
            'Comments',
            'Gigabases Expected',
            'Flowcell Type',
            'scRNA Core Number of Pools',
            'scrna core cells per chip well'
          ]
        end
      end
      .new
  end
  let(:scrna_config) do
    {
      desired_chip_loading_concentration: 2400,
      desired_number_of_runs: 2,
      volume_taken_for_cell_counting: 10,
      wastage_volume: 5,
      required_number_of_cells_per_sample_in_pool: 30_000,
      wastage_factor: 0.95
    }
  end

  before { allow(calculator).to receive(:scrna_config).and_return(scrna_config) }

  describe '#calculate_allowance_band' do
    context 'when validation to run calculate_allowance_band fails' do
      it 'returns empty hash if the template name does not match' do
        allow(calculator).to receive(:submission_template_name).and_return('Different Template')
        expect(calculator.calculate_allowance_band).to eq({})
      end

      it 'returns empty hash if required headers are missing' do
        allow(calculator).to receive(:validate_required_headers).and_return(false)
        expect(calculator.calculate_allowance_band).to eq({})
      end
    end

    context 'when validation to run calculate_allowance_band passes' do
      before { allow(calculator).to receive(:validate_required_headers).and_return(true) }

      it 'returns full allowance' do
        rows = [
          [
            'user',
            'Limber-Htp - scRNA Core cDNA Prep GEM-X 5p',
            'Test Project',
            'Test Study',
            'sub1',
            'NT1',
            nil,
            'ag1',
            nil,
            nil,
            nil,
            'Standard',
            nil,
            nil,
            nil,
            '108',
            '1',
            nil,
            nil,
            'Sample Comment',
            '1.35',
            nil,
            '1',
            '13000'
          ]
        ]
        allow(calculator).to receive_messages(
          group_rows_by_study_and_project: {
            ['Test Study', 'Test Project'] => rows
          },
          calculate_number_of_samples_in_smallest_pool: 6
        )
        expected_result = { { study: 'Test Study', project: 'Test Project' } => 'Full allowance' }
        expect(calculator.calculate_allowance_band).to eq(expected_result)
      end

      it 'returns `2 pool attempts, 1 count`' do
        rows = [
          [
            'user',
            'Limber-Htp - scRNA Core cDNA Prep GEM-X 5p',
            'Test Project',
            'Test Study',
            'sub1',
            'NT1',
            nil,
            'ag1',
            nil,
            nil,
            nil,
            'Standard',
            nil,
            nil,
            nil,
            '108',
            '1',
            nil,
            nil,
            'Sample Comment',
            '1.35',
            nil,
            '1',
            '5000'
          ]
        ]
        allow(calculator).to receive_messages(
          calculate_number_of_samples_in_smallest_pool: 2,
          group_rows_by_study_and_project: {
            ['Test Study', 'Test Project'] => rows
          }
        )
        expected_result = { { study: 'Test Study', project: 'Test Project' } => '2 pool attempts, 1 count' }
        expect(calculator.calculate_allowance_band).to eq(expected_result)
      end

      it 'returns `1 pool attempt, 1 count`' do
        rows = [
          [
            'user',
            'Limber-Htp - scRNA Core cDNA Prep GEM-X 5p',
            'Test Project',
            'Test Study',
            'sub1',
            'NT1',
            nil,
            'ag1',
            nil,
            nil,
            nil,
            'Standard',
            nil,
            nil,
            nil,
            '108',
            '1',
            nil,
            nil,
            'Sample Comment',
            '1.35',
            nil,
            '1',
            '19400'
          ]
        ]
        allow(calculator).to receive_messages(
          calculate_number_of_samples_in_smallest_pool: 2,
          group_rows_by_study_and_project: {
            ['Test Study', 'Test Project'] => rows
          }
        )
        expected_result = { { study: 'Test Study', project: 'Test Project' } => '1 pool attempt, 1 count' }
        expect(calculator.calculate_allowance_band).to eq(expected_result)
      end

      it 'returns no allowance' do
        rows = [
          [
            'user',
            'Limber-Htp - scRNA Core cDNA Prep GEM-X 5p',
            'Test Project',
            'Test Study',
            'sub1',
            'NT1',
            nil,
            'ag1',
            nil,
            nil,
            nil,
            'Standard',
            nil,
            nil,
            nil,
            '108',
            '1',
            nil,
            nil,
            'Sample Comment',
            '1.35',
            nil,
            '1',
            '3000'
          ]
        ]
        allow(calculator).to receive_messages(
          calculate_number_of_samples_in_smallest_pool: 1,
          group_rows_by_study_and_project: {
            ['Test Study', 'Test Project'] => rows
          }
        )
        expected_result = { { study: 'Test Study', project: 'Test Project' } => 'no allowance' }
        expect(calculator.calculate_allowance_band).to eq(expected_result)
      end
    end
  end
end
