# frozen_string_literal: true

require 'rails_helper'

# This is a very tangled test, as I'm hoping to unhook the current dependencies
# so need to wrap it at its current level of messiness
RSpec.describe PlateTemplateTask do
  subject(:task) { create(:plate_template_task) }

  let(:pipeline) { task.workflow.pipeline }
  let(:requests) do
    requests = []
    plate_a.wells.each do |well|
      requests << create(:cherrypick_request, asset: well, request_type: pipeline.request_types.first)
    end
    plate_b.wells.each do |well|
      requests << create(:cherrypick_request, asset: well, request_type: pipeline.request_types.first)
    end
    requests
  end
  let(:plate_a_barcode_number) { '1' }
  let(:plate_b_barcode_number) { '2' }
  let(:plate_a) do
    create(:plate, barcode: "SQPD-#{plate_a_barcode_number}", well_count: 4, well_factory: :untagged_well)
  end
  let(:plate_b) do
    create(:plate, barcode: "SQPD-#{plate_b_barcode_number}", well_count: 4, well_factory: :untagged_well)
  end

  let(:batch) { create(:batch, requests:, pipeline:) }
  let(:request) { instance_double(ActionDispatch::Request, parameters: params) }
  let(:workflow) { pipeline.workflow }

  let(:payload) do
    CSV.generate do |csv|
      csv << ['Request ID', 'Sample Name', 'Plate', 'Destination Well']
      batch.requests.each_with_index { |r, i| csv << [r.id, r.asset.samples.first.name, '1', "#{(65 + i).chr}1"] }
    end
  end
  let(:spreadsheet_layout) do
    [
      [
        [
          [requests[0].id, plate_a_barcode_number, 'SQPD-1:A1'],
          [requests[1].id, plate_a_barcode_number, 'SQPD-1:B1'],
          [requests[2].id, plate_a_barcode_number, 'SQPD-1:C1'],
          [requests[3].id, plate_a_barcode_number, 'SQPD-1:D1'],
          [requests[4].id, plate_b_barcode_number, 'SQPD-2:A1'],
          [requests[5].id, plate_b_barcode_number, 'SQPD-2:B1'],
          [requests[6].id, plate_b_barcode_number, 'SQPD-2:C1'],
          [requests[7].id, plate_b_barcode_number, 'SQPD-2:D1']
        ].concat(Array.new(96 - 8, [0, 'Empty', '']))
      ],
      %w[1 2]
    ]
  end

  let(:file) { instance_double(ActionDispatch::Http::UploadedFile, 'blank?' => false, :read => payload) }

  let(:workflow_controller) { instance_double(WorkflowsController, batch:) }
  let(:user) { build(:user) }

  describe '#render_task' do
    let(:workflow_controller) do
      wc = WorkflowsController.new
      wc.instance_variable_set(:@batch, batch)
      wc.request = request
      wc
    end
    let(:request) { instance_double(ActionDispatch::Request, parameters: params) }
    let(:params) { ActionController::Parameters.new(workflow_id: workflow.id) }

    it 'does stuff' do
      task.render_task(workflow_controller, params, user)
    end
  end

  describe '#do_task' do
    let(:params) do
      ActionController::Parameters.new(
        workflow_id: workflow.id,
        file:,
        plate_purpose_id: create(:plate_purpose).id
      )
    end

    it 'does stuff' do
      expect(workflow_controller).to receive(:spreadsheet_layout=).with(spreadsheet_layout)
      task.do_task(workflow_controller, params, user)
    end
  end

  describe Tasks::PlateTemplateHandler do
    describe '::generate_spreadsheet' do
      subject { described_class.generate_spreadsheet(batch) }

      let(:output) do
        CSV.generate(row_sep: "\r\n") do |csv|
          csv << ['Request ID', 'Sample Name', 'Source Plate', 'Source Well', 'Plate', 'Destination Well']
          csv << [requests[0].id, requests[0].asset.samples.first.name, 'SQPD-1', 'A1', '', '']
          csv << [requests[1].id, requests[1].asset.samples.first.name, 'SQPD-1', 'B1', '', '']
          csv << [requests[2].id, requests[2].asset.samples.first.name, 'SQPD-1', 'C1', '', '']
          csv << [requests[3].id, requests[3].asset.samples.first.name, 'SQPD-1', 'D1', '', '']
          csv << [requests[4].id, requests[4].asset.samples.first.name, 'SQPD-2', 'A1', '', '']
          csv << [requests[5].id, requests[5].asset.samples.first.name, 'SQPD-2', 'B1', '', '']
          csv << [requests[6].id, requests[6].asset.samples.first.name, 'SQPD-2', 'C1', '', '']
          csv << [requests[7].id, requests[7].asset.samples.first.name, 'SQPD-2', 'D1', '', '']
        end
      end

      it { is_expected.to eq(output) }
    end
  end
end
