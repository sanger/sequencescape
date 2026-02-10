# frozen_string_literal: true

require 'rails_helper'

# NB. Search for 'scRNA Core Pooling Developer Documentation' page in Confluence (public)
# for a more verbose explanation of the logic tested here.
RSpec.describe Submission::ScrnaCoreCdnaPrepPoolingPlanGenerator do
  describe '.calculate_pools_layout' do
    it 'evenly divides samples into pools when there is no remainder' do
      expect(described_class.calculate_pools_layout(12, 3)).to eq([4, 4, 4])
    end

    it 'distributes remainder samples across pools' do
      expect(described_class.calculate_pools_layout(14, 3)).to eq([5, 5, 4])
    end
  end

  describe '.grouped_labware' do
    let(:study) { create(:study) }
    let(:project) { create(:project) }
    let(:template) { create(:submission_template, name: 'Limber-Htp - scRNA Core cDNA Prep GEM-X 5p') }
    let(:library_request_type) { create(:library_request_type) }

    it 'groups labware by study and project' do # rubocop:disable RSpec/ExampleLength,RSpec/MultipleExpectations
      # Build the submission with the correct template and study/project associations
      submission_order = create(:order_with_submission, template_name: template.name, study: study,
                                                        project: project,
                                                        asset_group: create(:asset_group, study:))
      submission = submission_order.submission

      # Add sample tubes and requests to the submission
      sample_tubes = create_list(:sample_tube, 2, study:, project:)
      # Add sample tubes with the same study but different project to ensure grouping is correct
      project2 = create(:project)
      sample_tubes << create_list(:sample_tube, 2, study: study, project: project2)
      # Add sample tubes with the same project but different study to ensure grouping is correct
      study2 = create(:study)
      sample_tubes << create_list(:sample_tube, 3, study: study2, project: project)

      # Create library requests for each sample tube in the submission
      sample_tubes.flatten.each do |tube|
        create(:library_request, asset: tube.receptacle, submission: submission,
                                 request_type: library_request_type)
      end

      grouped = described_class.grouped_labware(submission)

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
  end

  describe '.generate_pooling_plan', skip: 'todo' do
    it 'generates a CSV string with the correct headers and pooling plan' do
      # Add test to check csv contents
    end
  end
end
