# frozen_string_literal: true

require 'rails_helper'

describe UatActions::UpdateStateOfRequestsInLabware do
  let(:tube_barcode) { tube.barcodes&.first&.barcode }
  let(:request_type_name) { request_sequencing1.request_type.name }
  let(:new_state) { 'passed' }

  let(:request_type_multiplexing) { create(:multiplex_request_type, name: 'RT Multiplexing', key: 'rt_multiplexing') }
  let(:request_type_sequencing) { create(:request_type, name: 'RT Sequencing', key: 'rt_sequencing') }

  let(:submission) { create(:submission) }
  let(:submission_id) { submission.id }

  # multiplexing requests passed, sequencing requests pending
  let(:request_multiplexing1) do
    create(
      :multiplex_request,
      request_type: request_type_multiplexing,
      state: 'passed',
      submission_id: submission_id
    )
  end
  let(:request_multiplexing2) do
    create(
      :multiplex_request,
      request_type: request_type_multiplexing,
      state: 'passed',
      submission_id: submission_id
    )
  end

  let(:request_sequencing1) do
    create(
      :sequencing_request,
      request_type: request_type_sequencing,
      state: 'pending',
      submission_id: submission_id
    )
  end
  let(:request_sequencing2) do
    create(
      :sequencing_request,
      request_type: request_type_sequencing,
      state: 'pending',
      submission_id: submission_id
    )
  end

  # create 2 aliquots for the tube, one for each multiplexing request
  let(:aliquot1) { create(:aliquot, request: request_multiplexing1) }
  let(:aliquot2) { create(:aliquot, request: request_multiplexing2) }

  # create a receptacle
  let(:receptacle) do
    create(:receptacle, aliquots: [aliquot1, aliquot2], requests_as_source: [request_sequencing1, request_sequencing2])
  end

  # create a tube with the aliquots, and the sequencing requests in requests_as_source
  let(:tube) do
    create(
      :multiplexed_library_tube,
      receptacle:
    )
  end

  let(:uat_action) { described_class.new(parameters) }

  let!(:saved_action) { uat_action.save }

  context 'with empty options' do
    let(:parameters) { {} }

    it 'returns a default' do
      expect(described_class.default).to be_a described_class
    end

    it 'has a nil labware_barcode' do
      expect(described_class.default.labware_barcode).to be_nil
    end

    it 'has a nil request_type_name' do
      expect(described_class.default.request_type_name).to be_nil
    end

    it 'has a nil new_state' do
      expect(described_class.default.new_state).to be_nil
    end

    it 'is invalid' do
      expect(uat_action.valid?).to be false
    end
  end

  context 'with valid options when request is in aliquot.request' do
    let(:request_multiplexing1) do
      create(
        :multiplex_request,
        request_type: request_type_multiplexing,
        state: 'pending',
        submission_id: submission_id
      )
    end
    let(:expected_report) do
      # A report is a hash of key value pairs which get returned to the user.
      # It should include information such as barcodes and identifiers
      {
        'labware_barcode' => tube_barcode,
        'request_type_name' => request_type_name,
        'new_state' => new_state,
        'updated_requests_count' => 2
      }
    end
    let(:request_multiplexing2) do
      create(
        :multiplex_request,
        request_type: request_type_multiplexing,
        state: 'pending',
        submission_id: submission_id
      )
    end
    let(:receptacle) do
      create(:receptacle, aliquots: [aliquot1, aliquot2], requests_as_source: [])
    end

    let(:request_type_name) { request_multiplexing1.request_type.name }

    before do
      allow(Labware).to receive(:find_by_barcode).with(tube_barcode).and_return(tube)
      allow(RequestType).to receive(:find_by).with(name: request_type_name).and_return(request_type_multiplexing)
    end

    context 'when valid parameters are provided' do
      let(:parameters) do
        {
          labware_barcode: tube_barcode,
          request_type_name: request_type_name,
          new_state: new_state
        }
      end

      it 'returns true when saved' do
        expect(saved_action).to be true
      end

      it 'sets the correct report after save' do
        expect(uat_action.report).to eq expected_report
      end

      it 'updates all tube requests to the new state' do
        expect(
          tube.aliquots.flat_map { |a| Array(a.request) }.compact.map(&:state)
        ).to all(eq 'passed')
      end
    end
  end

  context 'with valid options when requests are in requests_as_source' do
    before do
      # Ensure the tube and its requests are created before the UAT action is run
      # NB. had to go through receptacle for a tube as tube.requests_as_source was not working
      tube.receptacle.requests_as_source = [request_sequencing1, request_sequencing2]
      tube.save!
      tube.reload

      allow(Labware).to receive(:find_by_barcode).with(tube_barcode).and_return(tube)
      allow(RequestType).to receive(:find_by).with(name: request_type_name).and_return(request_type_sequencing)
    end

    let(:expected_report) do
      # A report is a hash of key value pairs which get returned to the user.
      # It should include information such as barcodes and identifiers
      {
        'labware_barcode' => tube_barcode,
        'request_type_name' => request_type_name,
        'new_state' => new_state,
        'updated_requests_count' => 2
      }
    end

    context 'when valid parameters are provided' do
      let(:parameters) do
        {
          labware_barcode: tube_barcode,
          request_type_name: request_type_name,
          new_state: new_state
        }
      end

      it 'returns true when saved' do
        expect(saved_action).to be true
      end

      it 'sets the correct report after save' do
        expect(uat_action.report).to eq expected_report
      end

      it 'updates all tube requests to the new state' do
        expect(tube.requests_as_source.pluck(:state)).to all(eq 'passed')
      end
    end
  end

  context 'with invalid options' do
    context 'when an invalid barcode is provided' do
      let(:tube) { nil }
      let(:parameters) do
        {
          labware_barcode: invalid_labware_barcode,
          request_type_name: request_type_name,
          new_state: new_state
        }
      end
      let(:invalid_labware_barcode) { 'INVALID' }

      before do
        allow(Labware).to receive(:find_by_barcode).with(invalid_labware_barcode).and_return(nil)
      end

      it 'is invalid' do
        expect(uat_action.valid?).to be false
      end

      it 'can not be saved' do
        expect(saved_action).to be false
      end

      it 'adds an error' do
        expect(uat_action.errors.full_messages).to include(
          'Labware not found.'
        )
      end
    end

    context 'when an invalid request type name is provided' do
      let(:invalid_request_type_name) { 'INVALID' }
      let(:parameters) do
        {
          labware_barcode: tube_barcode,
          request_type_name: invalid_request_type_name,
          new_state: new_state
        }
      end

      before do
        allow(RequestType).to receive(:find_by).with(name: invalid_request_type_name).and_return(nil)
      end

      it 'is invalid' do
        expect(uat_action.valid?).to be false
      end

      it 'can not be saved' do
        expect(saved_action).to be false
      end

      it 'adds an error' do
        expect(uat_action.errors.full_messages).to include(
          'Request type not found.'
        )
      end
    end

    context 'when an invalid state to transition the requests to is provided' do
      let(:invalid_new_state) { 'INVALID' }

      let(:parameters) do
        {
          labware_barcode: tube_barcode,
          request_type_name: request_type_name,
          new_state: invalid_new_state
        }
      end

      it 'is valid to try to update the state' do
        expect(uat_action.valid?).to be true
      end

      it 'can not be saved' do
        expect(saved_action).to be false
      end

      it 'adds an error' do
        expect(uat_action.errors.full_messages).to include(
          'Request type name Failed to update request state, error message: Validation failed: State is invalid'
        )
      end
    end
  end
end
