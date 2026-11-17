# frozen_string_literal: true

require 'rails_helper'
require 'shared_contexts/sapio_reception_shared_context'

# Sapio reception and work order from end to end: the reception creates the
# plate and its samples, then the work order task creates and builds the
# submission for them. How these specs work:
# spec/shared_contexts/sapio_reception_shared_context.rb
describe 'Sapio reception and work order',
         :sapio_operations_endpoint_enabled, :sapio_reception_enabled do
  include_context 'with Sapio reception'

  let(:work_order) do
    { external_id: 'WO-1', service_name: 'Human Exome Ultra low input DNA (LCMB) - FS-shear',
      requested_by: user.login, cost_code: 'S1234',
      requested_labware_identifiers: ['SAPIO-PLATE-1:A1'],
      options: { fragment_size_required_from: 1, fragment_size_required_to: 20 } }
  end
  let(:user) { create(:user) }
  let(:request_with_work_order) do
    reception_request(plate('SAPIO-PLATE-1', 'A1' => sample('SAPIO-1-1'))).merge(work_order:)
  end

  before do
    stub_const('ApiOperation::TASKS', { 'reception_and_work_order' => %w[reception work_order] })
    create(:limber_wgs_submission_template, name: 'Limber-Htp - LCMB')
    create(:plate_purpose, name: 'LCMB Cherrypick')
  end

  context 'with a valid work order' do
    let!(:operation) { post_and_process(request_with_work_order) }

    it 'completes the work order' do
      expect([operation.reload.status, operation.error_details]).to eq(['work_order_completed', nil])
    end

    it 'creates the submission of the work order' do
      expect(Submission.find_by!(name: 'WO-1').orders.map(&:study)).to eq([study])
    end

    it 'creates the project of the cost code for the submission' do
      expect(Submission.find_by!(name: 'WO-1').orders.map { it.project.name }).to eq(['SAPIO-S1234'])
    end
  end

  context 'with a work order that has errors' do
    let(:work_order) { super().merge(requested_labware_identifiers: ['UNKNOWN-1']) }
    let!(:operation) { post_and_process(request_with_work_order) }

    it 'fails the work order after the reception' do
      expect(operation.reload.status).to eq('work_order_failed')
    end

    it 'keeps the labware the reception created' do
      expect(Barcode.find_by(barcode: 'SAPIO-PLATE-1')).to be_present
    end

    it 'creates no submission' do
      expect(Submission.count).to eq(0)
    end
  end

  context 'without a work order' do
    let!(:operation) { post_and_process(reception_request(plate('SAPIO-PLATE-1', 'A1' => sample('SAPIO-1-1')))) }

    it 'completes the work order without creating a submission' do
      expect([operation.reload.status, Submission.count]).to eq(['work_order_completed', 0])
    end
  end
end
