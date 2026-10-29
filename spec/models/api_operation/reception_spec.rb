# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApiOperation::Reception do
  subject(:reception) { described_class.new(api_operation) }

  let(:api_operation) do
    create(:api_operation, payload: { labware: [labware] }.to_json)
  end

  def labware_with(barcode, type: 'plate96')
    { uuid: SecureRandom.uuid, barcode: barcode, type: type, receptacles: [] }
  end

  context 'with new labware' do
    let(:labware) { labware_with('UNKNOWN-1') }

    it 'finds no errors' do
      expect(reception.call).to be_empty
    end
  end

  context 'with known labware that is the same' do
    let(:plate) { create(:plate) }
    let(:labware) { labware_with(plate.human_barcode) }

    it 'finds no errors' do
      expect(reception.call).to be_empty
    end
  end

  context 'with new labware that is not valid' do
    let(:labware) { labware_with('UNKNOWN-1', type: 'tube') }

    it 'reports the problem' do
      expect(reception.call).to eq(
        [{ pointer: '/labware/0/receptacles',
           detail: 'A tube has one receptacle, not 0' }]
      )
    end
  end

  context 'with known labware that differs' do
    let(:plate) { create(:plate) }
    let(:labware) { labware_with(plate.human_barcode, type: 'tube') }

    it 'reports the conflict' do
      expect(reception.call).to eq(
        [{ pointer: '/labware/0/type',
           detail: "#{plate.human_barcode} is a 96-well plate in " \
                   'Sequencescape, not a tube' }]
      )
    end
  end

  context "with a sample whose study's UUID is in upper case" do
    let(:study) { create(:study) }
    let(:sample) do
      { uuid: SecureRandom.uuid, study_uuid: study.uuid.upcase,
        sanger_sample_id: 'SAMPLE-1', supplier_sample_name: 'Supplier sample' }
    end
    let(:labware) do
      labware_with('UNKNOWN-1').merge(
        receptacles: [{ position: 'A1', uuid: SecureRandom.uuid,
                        samples: [sample] }]
      )
    end

    it 'finds the study' do
      expect(reception.call).to be_empty
    end

    it 'links the new sample to it' do
      reception.call
      expect(Sample.find_by!(sanger_sample_id: 'SAMPLE-1').studies)
        .to contain_exactly(study)
    end
  end

  describe 'creating the new labware' do
    let(:creation) do
      instance_double(ApiOperation::Reception::Creation, call: nil)
    end

    before do
      allow(ApiOperation::Reception::Creation)
        .to receive(:new).and_return(creation)
      reception.call
    end

    context 'when nothing is wrong' do
      let(:labware) { labware_with('UNKNOWN-1') }

      it 'is given the new labware' do
        expect(ApiOperation::Reception::Creation).to have_received(:new)
          .with([having_attributes(barcode: 'UNKNOWN-1')])
      end

      it 'creates it' do
        expect(creation).to have_received(:call)
      end
    end

    context 'when the only labware is known' do
      let(:plate) { create(:plate) }
      let(:labware) { labware_with(plate.human_barcode) }

      it 'is given no labware' do
        expect(ApiOperation::Reception::Creation)
          .to have_received(:new).with([])
      end
    end

    context 'when something is wrong' do
      let(:labware) { labware_with('UNKNOWN-1', type: 'tube') }

      it 'creates nothing' do
        expect(creation).not_to have_received(:call)
      end
    end
  end
end
