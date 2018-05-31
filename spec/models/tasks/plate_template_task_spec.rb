# frozen_string_literal: true

require 'rails_helper'

# This is a very tangled test, as I'm hoping to unhook the current dependencies
# so need to wrap it at its current level of messiness
RSpec.describe PlateTemplateTask, type: :model do
  subject(:task) { create :plate_template_task }

  let(:batch) { create :cherrypicking_batch, request_count: 8 }
  let(:request) { instance_double(ActionDispatch::Request, parameters: params) }
  let(:workflow) { create :workflow }
  let(:payload) do
    CSV.generate do |csv|
      csv << ['Request ID', 'Sample Name', 'Plate', 'Destination Well']
      batch.requests.each_with_index do |r, i|
        csv << [r.id, r.asset.samples.first.name, '1', "#{(65 + i).chr}1"]
      end
    end
  end
  let(:spreadsheet_layout) do
    [
      [
        batch.requests.each_with_index.map { |r, _i| [r.id, r.asset.plate.barcode_number, r.asset.display_name] }.concat(Array.new(96 - 8, [0, 'Empty', '']))
      ],
      batch.requests.map { |r| r.asset.plate.barcode_number }.uniq
    ]
  end

  let(:file) { instance_double(ActionDispatch::Http::UploadedFile, 'blank?' => false, read: payload) }

  let(:workflow_controller) do
    wc = WorkflowsController.new
    wc.instance_variable_set('@batch', batch)
    wc.request = request
    wc
  end

  describe '#render_task' do
    let(:params) { ActionController::Parameters.new(workflow_id: workflow.id) }
    it 'does stuff' do
      task.render_task(workflow_controller, params)
    end
  end

  describe '#do_task' do
    let(:params) { ActionController::Parameters.new(workflow_id: workflow.id, file: file, plate_purpose_id: create(:plate_purpose).id) }
    it 'does stuff' do
      task.do_task(workflow_controller, params)
      expect(workflow_controller.instance_variable_get('@spreadsheet_layout')).to eq(spreadsheet_layout)
    end
  end
end
