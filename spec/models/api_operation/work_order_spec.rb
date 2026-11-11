# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApiOperation::WorkOrder do
  subject(:work_order) { described_class.new(api_operation) }

  let(:details) do
    { external_id: 'WO1', service_name: 'Human Exome Ultra low input DNA (LCMB) - FS-shear',
      requested_by: 'user', cost_code: 'S1234', requested_labware_identifiers: ['DN1:A1'], options: {} }
  end
  let(:api_operation) { create(:api_operation, payload: { work_order: details }.to_json) }

  context 'with a valid work order and an existing template' do
    let(:creation) { instance_double(ApiOperation::WorkOrder::SubmissionCreation, call: []) }
    let!(:template) { create(:submission_template, name: 'Limber-Htp - LCMB') }

    before do
      create(:plate_purpose, name: 'LCMB Cherrypick')
      allow(ApiOperation::WorkOrder::Validation::Validation).to receive(:new).and_return(
        instance_double(ApiOperation::WorkOrder::Validation::Validation, errors: [])
      )
      allow(ApiOperation::WorkOrder::SubmissionCreation).to receive(:new).and_return(creation)
    end

    it 'creates the submission from the resolved template' do
      work_order.call
      expect(ApiOperation::WorkOrder::SubmissionCreation)
        .to have_received(:new).with(api_operation, template, project: instance_of(Project),
                                                              requested_receptacles: anything)
    end

    it 'returns the errors of the creation' do
      allow(creation).to receive(:call).and_return([{ pointer: '/work_order', detail: 'bad' }])
      expect(work_order.call).to eq([{ pointer: '/work_order', detail: 'bad' }])
    end
  end

  context 'without a cost code' do
    before do
      create(:submission_template, name: 'Limber-Htp - LCMB')
      details[:cost_code] = ' '
    end

    it 'points at the cost code' do
      expect(work_order.call.pluck(:pointer)).to eq(['/work_order/cost_code'])
    end

    it 'creates no project' do
      expect { work_order.call }.not_to change(Project, :count)
    end
  end

  context 'when a requested labware does not exist' do
    before { create(:submission_template, name: 'Limber-Htp - LCMB') }

    it 'reports it without creating a submission' do
      allow(ApiOperation::WorkOrder::SubmissionCreation).to receive(:new)
      expect(work_order.call.pluck(:pointer)).to eq(['/work_order/requested_labware_identifiers/0'])
    end
  end

  context 'without a service name' do
    let(:details) { { requested_labware_identifiers: ['DN1:A1'] } }

    it 'points at the service name' do
      expect(work_order.call).to eq([{ pointer: '/work_order/service_name', detail: "Service name can't be blank" }])
    end
  end

  context 'without requested labware identifiers' do
    let(:details) { { service_name: 'Human Exome', cost_code: 'S1234' } }

    before { create(:submission_template, name: 'Limber-Htp - ISC') }

    it 'points at the identifiers' do
      expect(work_order.call.pluck(:pointer)).to include('/work_order/requested_labware_identifiers')
    end
  end

  context 'with a service that is not mapped' do
    let(:details) { { service_name: 'Nope', requested_labware_identifiers: ['DN1:A1'] } }

    it 'reports the unknown service' do
      expect(work_order.call).to eq([{ pointer: '/work_order/service_name',
                                       detail: "Unknown Sapio service 'Nope' for Sequencescape" }])
    end
  end

  context 'when the template does not exist' do
    it 'reports the missing template' do
      expect(work_order.call.first[:detail]).to include('Cannot find template')
    end
  end
end
