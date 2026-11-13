# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApiOperation::WorkOrder::SubmissionCreation do
  subject(:creation) { described_class.new(api_operation, template) }

  let(:study) { create(:study) }
  let(:project) { create(:project, name: 'SAPIO-COST1', project_metadata_attributes: { project_cost_code: 'COST1' }) }
  let(:user) { create(:user) }
  let(:plate) { create(:plate_with_untagged_wells, well_count: 2, studies: [study]) }
  let(:well) { plate.wells.located_at('A1').first }
  let(:template) do
    create(:limber_wgs_submission_template, study:, project:)
  end
  let(:details) do
    {
      external_id: 'WO-1',
      requested_by: user.login,
      cost_code: 'COST1',
      requested_labware_identifiers: ["#{plate.human_barcode}:A1"],
      options: {
        read_length: 150,
        fragment_size_required_from: 100,
        fragment_size_required_to: 300,
        number_of_lanes: 2,
        priority: 'High'
      }
    }
  end
  let(:api_operation) { create(:api_operation, payload: { work_order: details }.to_json) }

  before { well.samples.first.studies << study }

  context 'with a valid work order' do
    it 'finds no errors' do
      expect(creation.call).to be_empty
    end

    it 'creates a built submission named after the work order, with its priority' do
      creation.call
      expect(Submission.find_by(name: 'WO-1')).to have_attributes(user: user, priority: 3)
    end

    it 'submits the requested well with the project and study' do
      creation.call
      order = Submission.find_by(name: 'WO-1').orders.first
      expect(order).to have_attributes(project: project, study: study, assets: [well])
    end
  end

  context 'with an unknown user' do
    before { details[:requested_by] = 'nobody' }

    it 'points at requested_by' do
      expect(creation.call.pluck(:pointer)).to eq(['/work_order/requested_by'])
    end
  end

  context 'with an unknown cost code' do
    before { details[:cost_code] = 'NOPE' }

    it 'points at cost_code, as the new Sapio project is not approved for submissions' do
      expect(creation.call.pluck(:pointer)).to eq(['/work_order/cost_code'])
    end
  end

  context 'when the receptacles belong to different studies' do
    let(:other_study) { create(:study) }
    let(:other_well) { plate.wells.last }

    before do
      other_well.aliquots.each { |aliquot| aliquot.update!(study: other_study) }
      details[:requested_labware_identifiers] << "#{plate.human_barcode}:#{other_well.map_description}"
    end

    it 'makes an order per study' do
      creation.call
      expect(Submission.last.orders.map(&:study)).to contain_exactly(study, other_study)
    end
  end

  context 'with an unknown library type' do
    before { details[:options][:library_type] = 'Nonexistent' }

    it 'points at the library type option' do
      expect(creation.call.pluck(:pointer)).to eq(['/work_order/options/library_type'])
    end
  end
end
