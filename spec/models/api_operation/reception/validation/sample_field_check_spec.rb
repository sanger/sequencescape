# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApiOperation::Reception::Validation::SampleFieldCheck do
  subject(:check) { described_class.new(input) }

  let(:input) do
    ApiOperation::Reception::Validation::Input.build([labware], [labware])
  end
  let(:labware) do
    ApiOperation::Reception::Payload::PayloadLabware.new(
      uuid: SecureRandom.uuid, barcode: 'BARCODE-1', type: type,
      receptacles: receptacles, pointer: '/labware/0'
    )
  end
  let(:type) { 'plate96' }
  let(:reference_genome) { create(:reference_genome) }

  # A receptacle at the index and position, with one sample with the fields
  def receptacle(index, position, supplier_sample_name: 'Supplier sample',
                 **fields)
    pointer = "/labware/0/receptacles/#{index}"
    sample = ApiOperation::Reception::Payload::PayloadSample.new(
      uuid: SecureRandom.uuid, study_uuid: SecureRandom.uuid,
      sanger_sample_id: "SAMPLE-#{index}",
      supplier_sample_name: supplier_sample_name,
      fields: fields.stringify_keys, pointer: "#{pointer}/samples/0"
    )
    ApiOperation::Reception::Payload::PayloadReceptacle.new(
      position: position, uuid: SecureRandom.uuid, samples: [sample],
      pointer: pointer
    )
  end

  def pointer(index, field)
    "/labware/0/receptacles/#{index}/samples/0/#{field}"
  end

  context 'with samples without these fields' do
    let(:receptacles) { [receptacle(0, 'A1')] }

    it 'finds no errors' do
      expect(check.errors).to be_empty
    end

    it 'makes no queries' do
      receptacles
      expect(queries_in { check.errors }).to be_empty
    end
  end

  context 'with an existing reference genome, in another case' do
    let(:receptacles) do
      [receptacle(0, 'A1', reference_genome: reference_genome.name.upcase)]
    end

    it 'finds no errors' do
      expect(check.errors).to be_empty
    end
  end

  context 'with a reference genome that does not exist, named twice' do
    let(:receptacles) do
      [receptacle(0, 'A1', reference_genome: 'Unknown'),
       receptacle(1, 'B1', reference_genome: 'Unknown')]
    end

    it 'reports it once, at its first sample' do
      expect(check.errors).to eq(
        [{ pointer: pointer(0, 'reference_genome'),
           detail: 'No reference genome named Unknown (used by 2 samples)' }]
      )
    end
  end

  context 'with several reference genomes' do
    let(:receptacles) do
      [receptacle(0, 'A1', reference_genome: reference_genome.name),
       receptacle(1, 'B1', reference_genome: 'Unknown')]
    end

    # Built first, so creating the reference genome isn't counted
    before { receptacles }

    it 'looks them up in one query' do
      expect(queries_in { check.errors }.size).to eq(1)
    end
  end

  context 'with the same control type in both fields' do
    let(:receptacles) do
      [receptacle(0, 'A1', supplier_sample_name: 'CONTROL_1',
                           control_type: 'pcr positive',
                           bioscan_control_type: 'pcr positive')]
    end

    it 'finds no errors' do
      expect(check.errors).to be_empty
    end
  end

  context 'with different control types in the two fields' do
    let(:receptacles) do
      [receptacle(0, 'A1', supplier_sample_name: 'CONTROL_1',
                           control_type: 'positive',
                           bioscan_control_type: 'pcr positive')]
    end

    it 'reports the Bioscan field' do
      expect(check.errors).to eq(
        [{ pointer: pointer(0, 'bioscan_control_type'),
           detail: 'bioscan_control_type (pcr positive) differs from ' \
                   'control_type (positive)' }]
      )
    end
  end

  context 'with Bioscan controls named and placed as the manifest requires' do
    let(:receptacles) do
      [receptacle(0, 'A1', supplier_sample_name: 'CONTROL_1',
                           bioscan_control_type: 'pcr positive'),
       receptacle(1, 'B1', supplier_sample_name: 'Supplier sample',
                           bioscan_supplier_name: 'CONTROL_2',
                           bioscan_control_type: 'pcr negative'),
       receptacle(2, 'H12', supplier_sample_name: 'CONTROL_3',
                            bioscan_control_type: 'lysate negative')]
    end

    it 'finds no errors' do
      expect(check.errors).to be_empty
    end
  end

  context 'with a Bioscan control whose supplier name is not a control name' do
    let(:receptacles) do
      [receptacle(0, 'A1', bioscan_control_type: 'pcr positive')]
    end

    it 'reports the supplier name' do
      expect(check.errors).to eq(
        [{ pointer: pointer(0, 'supplier_sample_name'),
           detail: 'A control needs a supplier name beginning with CONTROL_' }]
      )
    end
  end

  context 'with a Bioscan supplier name that is not a control name' do
    let(:receptacles) do
      [receptacle(0, 'A1', supplier_sample_name: 'CONTROL_1',
                           bioscan_supplier_name: 'Bioscan sample',
                           bioscan_control_type: 'pcr positive')]
    end

    it 'reports the Bioscan supplier name, which the sample gets' do
      expect(check.errors.sole[:pointer])
        .to eq(pointer(0, 'bioscan_supplier_name'))
    end
  end

  context 'with a supplier name that is only CONTROL_' do
    let(:receptacles) do
      [receptacle(0, 'A1', supplier_sample_name: 'CONTROL_',
                           bioscan_control_type: 'pcr positive')]
    end

    it 'reports it' do
      expect(check.errors.sole[:pointer])
        .to eq(pointer(0, 'supplier_sample_name'))
    end
  end

  context 'with a non-Bioscan control without a control name' do
    let(:receptacles) { [receptacle(0, 'A1', control_type: 'positive')] }

    it 'finds no errors' do
      expect(check.errors).to be_empty
    end
  end

  context 'with a pcr negative control in H12' do
    let(:receptacles) do
      [receptacle(0, 'H12', supplier_sample_name: 'CONTROL_1',
                            bioscan_control_type: 'pcr negative')]
    end

    it 'reports it' do
      expect(check.errors).to eq(
        [{ pointer: pointer(0, 'bioscan_control_type'),
           detail: "A pcr negative control can't be in H12" }]
      )
    end
  end

  context 'with a lysate negative control in another well' do
    let(:receptacles) do
      [receptacle(0, 'A1', supplier_sample_name: 'CONTROL_1',
                           bioscan_control_type: 'lysate negative')]
    end

    it 'reports it' do
      expect(check.errors).to eq(
        [{ pointer: pointer(0, 'bioscan_control_type'),
           detail: 'A lysate negative control must be in H12, not A1' }]
      )
    end
  end

  context 'with a lysate negative control in a tube' do
    let(:type) { 'tube' }
    let(:receptacles) do
      [receptacle(0, nil, supplier_sample_name: 'CONTROL_1',
                          bioscan_control_type: 'lysate negative')]
    end

    it 'reports it' do
      expect(check.errors.sole[:detail])
        .to eq('A lysate negative control must be in H12, not in a tube')
    end
  end

  context 'with a pcr positive control in a tube' do
    let(:type) { 'tube' }
    let(:receptacles) do
      [receptacle(0, nil, supplier_sample_name: 'CONTROL_1',
                          bioscan_control_type: 'pcr positive')]
    end

    it 'finds no errors' do
      expect(check.errors).to be_empty
    end
  end

  context 'with a non-Bioscan lysate negative control in another well' do
    let(:receptacles) do
      [receptacle(0, 'A1', control_type: 'lysate negative')]
    end

    it 'finds no errors' do
      expect(check.errors).to be_empty
    end
  end

  # The SQL queries the block runs
  def queries_in(&)
    queries = []
    count = ->(*, payload) { queries << payload[:sql] }
    ActiveSupport::Notifications.subscribed(count, 'sql.active_record', &)
    queries
  end
end
