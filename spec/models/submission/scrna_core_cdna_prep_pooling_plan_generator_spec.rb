# frozen_string_literal: true

require 'rails_helper'

# NB. Search for 'scRNA Core Pooling Developer Documentation' page in Confluence (public)
# for a more verbose explanation of the logic tested here.
RSpec.describe Submission::ScrnaCoreCdnaPrepPoolingPlanGenerator do
  let(:study) { create(:study) }
  let(:project) { create(:project) }
  let(:template) { create(:submission_template, name: 'Limber-Htp - scRNA Core cDNA Prep GEM-X 5p') }
  let(:submission) do
    submission_order = create(:order_with_submission, template_name: template.name, study: study,
                                                      project: project,
                                                      asset_group: create(:asset_group, study:))
    submission_order.submission
  end

  describe '.generate_pooling_plan' do
    it 'generates a CSV string with the correct headers' do
      # A basic submission is fine for testing the headers
      submission = create(:submission)
      csv_string = described_class.generate_pooling_plan(submission)
      csv = CSV.parse(csv_string, headers: true)

      expect(csv.headers).to eq(['Study / Project', 'Pools (num samples)', 'Cells per chip well'])
    end

    it 'generates a CSV string with the correct pooling plan based on the submission requests' do # rubocop:disable RSpec/MultipleExpectations, RSpec/ExampleLength
      # Add sample tubes and requests to the submission
      create_list(:sample_tube, 5, study:, project:).each do |tube|
        create(:customer_request, sti_type: 'PbmcPoolingCustomerRequest', asset: tube.receptacle,
                                  submission: submission,
                                  initial_study: study, initial_project: project,
                                  request_metadata_attributes: { number_of_pools: 3, cells_per_chip_well: 100 })
      end

      csv_string = described_class.generate_pooling_plan(submission)
      csv = CSV.parse(csv_string, headers: true)

      expect(csv.length).to eq(1) # We have one study/project group
      expect(csv[0]['Study / Project']).to eq("#{study.name} / #{project.name}")
      expect(csv[0]['Pools (num samples)']).to eq('2, 2, 1') # With 5 samples and 3 pools, we expect a layout of 2, 2, 1
      expect(csv[0]['Cells per chip well']).to eq('100') # We set this in the request metadata for each request
    end

    it 'handles multiple study/project groups correctly' do # rubocop:disable RSpec/ExampleLength, RSpec/MultipleExpectations
      # Add sample tubes and requests for two different study/project groups
      project2 = create(:project)
      study2 = create(:study)

      create_list(:sample_tube, 4, study:, project:).each do |tube|
        create(:customer_request, sti_type: 'PbmcPoolingCustomerRequest', asset: tube.receptacle,
                                  submission: submission,
                                  initial_study: study, initial_project: project,
                                  request_metadata_attributes: { number_of_pools: 2, cells_per_chip_well: 50 })
      end

      create_list(:sample_tube, 8, study: study2, project: project2).each do |tube|
        create(:customer_request, sti_type: 'PbmcPoolingCustomerRequest', asset: tube.receptacle,
                                  submission: submission,
                                  initial_study: study2, initial_project: project2,
                                  request_metadata_attributes: { number_of_pools: 3, cells_per_chip_well: 150 })
      end

      csv_string = described_class.generate_pooling_plan(submission)
      csv = CSV.parse(csv_string, headers: true)

      expect(csv.length).to eq(2) # We have two study/project groups

      group1 = csv.find { |row| row['Study / Project'] == "#{study.name} / #{project.name}" }
      expect(group1['Pools (num samples)']).to eq('2, 2') # With 4 samples and 2 pools, we expect a layout of 2, 2
      expect(group1['Cells per chip well']).to eq('50')

      group2 = csv.find { |row| row['Study / Project'] == "#{study2.name} / #{project2.name}" }
      expect(group2['Pools (num samples)']).to eq('3, 3, 2') # With 8 samples and 3 pools, we expect a layout of 3, 3, 2
      expect(group2['Cells per chip well']).to eq('150')
    end
  end

  describe '.calculate_pools_layout' do
    it 'evenly divides samples into pools when there is no remainder' do
      expect(described_class.calculate_pools_layout(12, 3)).to eq([4, 4, 4])
    end

    it 'distributes remainder samples across pools' do
      expect(described_class.calculate_pools_layout(14, 3)).to eq([5, 5, 4])
    end
  end

  describe '.grouped_requests' do
    it 'groups requests by study and project' do # rubocop:disable RSpec/ExampleLength,RSpec/MultipleExpectations
      # Add sample tubes and requests to the submission
      create_list(:sample_tube, 2, study:, project:).each do |tube|
        create(:customer_request, sti_type: 'PbmcPoolingCustomerRequest', asset: tube.receptacle,
                                  submission: submission, initial_study: study, initial_project: project,
                                  request_metadata_attributes: { number_of_pools: 1, cells_per_chip_well: 150 })
      end

      # Add sample tubes with the same study but different project to ensure grouping is correct
      project2 = create(:project)
      create_list(:sample_tube, 2, study: study, project: project2).each do |tube|
        create(:customer_request, sti_type: 'PbmcPoolingCustomerRequest', asset: tube.receptacle,
                                  submission: submission, initial_study: study, initial_project: project2,
                                  request_metadata_attributes: { number_of_pools: 1, cells_per_chip_well: 150 })
      end

      # Add sample tubes with the same project but different study to ensure grouping is correct
      study2 = create(:study)
      create_list(:sample_tube, 3, study: study2, project: project).each do |tube|
        create(:customer_request, sti_type: 'PbmcPoolingCustomerRequest', asset: tube.receptacle,
                                  submission: submission, initial_study: study2, initial_project: project,
                                  request_metadata_attributes: { number_of_pools: 1, cells_per_chip_well: 150 })
      end

      grouped = described_class.grouped_requests(submission)

      expected_groups = {
        "#{study.name} / #{project.name}" => 2,
        "#{study.name} / #{project2.name}" => 2,
        "#{study2.name} / #{project.name}" => 3
      }

      expect(grouped.keys).to match_array(expected_groups.keys)
      expected_groups.each do |group, count|
        expect(grouped[group].size).to eq(count)
      end
    end

    it 'counts each sample tube only once even if it appears in multiple requests' do # rubocop:disable RSpec/ExampleLength,RSpec/MultipleExpectations
      # Create a sample tube
      tube = create(:sample_tube, study:, project:)
      # Create multiple requests for the same tube
      create_list(:customer_request, 3, sti_type: 'PbmcPoolingCustomerRequest', asset: tube.receptacle,
                                        submission: submission, initial_study: study, initial_project: project,
                                        request_metadata_attributes: { number_of_pools: 1, cells_per_chip_well: 150 })

      # Create some other requests for different tubes to ensure the grouping logic is still correct
      create_list(:sample_tube, 2, study:, project:).each do |tube|
        create(:customer_request, sti_type: 'PbmcPoolingCustomerRequest', asset: tube.receptacle,
                                  submission: submission, initial_study: study, initial_project: project,
                                  request_metadata_attributes: { number_of_pools: 1, cells_per_chip_well: 150 })
      end

      grouped = described_class.grouped_requests(submission)

      expect(grouped.keys).to eq(["#{study.name} / #{project.name}"])
      # 3 as we only have 3 requests with uniq assets.
      expect(grouped["#{study.name} / #{project.name}"].size).to eq(3)
    end
  end
end
