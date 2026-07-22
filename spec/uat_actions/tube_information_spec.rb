# frozen_string_literal: true

require 'rails_helper'

describe UatActions::TubeInformation do
  context 'when the tube barcode does not match a tube' do
    let(:parameters) { { tube_barcode: 'INVALID' } }
    let(:uat_action) { described_class.new(parameters) }
    let(:report) do
      {
        tube_barcode: 'INVALID'
      }
    end

    it 'cannot be performed' do
      expect(uat_action.perform).to be false
    end

    it 'returns an empty report with the tube barcode' do
      uat_action.perform
      expect(uat_action.report).to eq report
    end
  end

  context 'when the tube exists' do
    let(:tube_barcode) { create(:fluidx) }
    let(:parameters) { { tube_barcode: tube_barcode.barcode } }
    let(:uat_action) { described_class.new(parameters) }
    let(:submission) { create(:submission) }
    let(:submission_id) { submission.id }

    let(:request_type_multiplexing) { create(:multiplex_request_type, name: 'RT Multiplexing', key: 'rt_multiplexing') }
    let(:request_type_sequencing) { create(:request_type, name: 'RT Sequencing', key: 'rt_sequencing') }

    let(:request_multiplexing1) do
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

    let(:aliquot1) { create(:aliquot, request: request_multiplexing1) }

    # create a receptacle
    let(:receptacle) do
      create(:receptacle, aliquots: [aliquot1],
                          requests_as_source: [request_multiplexing1, request_sequencing1])
    end

    # create a tube with the aliquots, and the sequencing requests in requests_as_source
    let(:tube) do
      create(
        :multiplexed_library_tube,
        barcodes: [tube_barcode],
        receptacle: receptacle
      )
    end

    before do
      # Ensure the tube and its requests are created before the UAT action is run
      # NB. had to go through receptacle for a tube as tube.requests_as_source was not working
      tube.receptacle.requests_as_source = [request_multiplexing1, request_sequencing1]
      tube.save!
      tube.reload

      allow(Labware).to receive(:find_by_barcode).with(tube_barcode.barcode).and_return(tube)
      allow(RequestType).to receive(:find_by)
        .with(name: request_type_sequencing.name)
        .and_return(request_type_sequencing)
    end

    # A tube with active requests_as_source
    context 'when the tube has an active submission' do
      let(:report) do
        {
          tube_barcode: tube_barcode.barcode,
          tube_purpose: tube.purpose.name,
          tube_requests_as_source_types: ['RT Sequencing']
        }
      end

      it 'can be performed' do
        expect(uat_action.perform).to be true
      end

      it 'returns a report with the tube barcode and no active requests' do
        uat_action.perform
        expect(uat_action.report).to eq report
      end
    end

    # This test is for a scenario where there are only completed submissions on the tube
    context 'when the tube has completed submissions' do
      let(:report) do
        {
          tube_barcode: tube_barcode.barcode,
          tube_purpose: tube.purpose.name,
          tube_requests_as_source_types: []
        }
      end

      let(:request_sequencing1) do
        create(
          :sequencing_request,
          request_type: request_type_sequencing,
          state: 'passed',
          submission_id: submission_id
        )
      end

      it 'can be performed' do
        expect(uat_action.perform).to be true
      end

      it 'returns a report with the tube barcode and no active requests' do
        uat_action.perform
        expect(uat_action.report).to eq report
      end
    end
  end

  it 'returns a default' do
    expect(described_class.default).to be_a described_class
  end
end
