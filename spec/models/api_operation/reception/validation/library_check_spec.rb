# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApiOperation::Reception::Validation::LibraryCheck do
  subject(:check) { described_class.new(input) }

  let(:input) do
    ApiOperation::Reception::Validation::Input.new(
      payload_labware: [], new_labware: [], new_samples: samples
    )
  end
  let(:library_type) { create(:library_type) }
  let(:primer_panel) { create(:primer_panel) }

  # A sample in the receptacle at the index, with the library fields
  def sample(index, **fields)
    ApiOperation::Reception::Payload::PayloadSample.new(
      uuid: SecureRandom.uuid, study_uuid: SecureRandom.uuid,
      sanger_sample_id: "SAMPLE-#{index}",
      supplier_sample_name: "Supplier sample #{index}",
      fields: fields.stringify_keys,
      pointer: "/labware/0/receptacles/#{index}/samples/0"
    )
  end

  def pointer(index, field)
    "/labware/0/receptacles/#{index}/samples/0/#{field}"
  end

  context 'with existing names, in any case' do
    let(:samples) do
      [sample(0, library_type: library_type.name.upcase,
                 primer_panel: primer_panel.name),
       sample(1, library_type_long_read: library_type.name,
                 insert_size_from: 100, insert_size_to: 200)]
    end

    it 'finds no errors' do
      expect(check.errors).to be_empty
    end
  end

  context 'with samples without library fields' do
    let(:samples) { [sample(0)] }

    it 'finds no errors' do
      expect(check.errors).to be_empty
    end
  end

  context 'with a library type that does not exist, named by several samples' do
    let(:samples) do
      [sample(0, library_type: 'Unknown'), sample(1, library_type: 'Unknown')]
    end

    it 'reports it once, at its first sample' do
      expect(check.errors).to eq(
        [{ pointer: pointer(0, 'library_type'),
           detail: 'No library type named Unknown (used by 2 samples)' }]
      )
    end
  end

  context 'with a long read library type that does not exist' do
    let(:samples) { [sample(0, library_type_long_read: 'Unknown')] }

    it 'reports it' do
      expect(check.errors.sole[:pointer])
        .to eq(pointer(0, 'library_type_long_read'))
    end
  end

  context 'with a primer panel that does not exist' do
    let(:samples) { [sample(0, primer_panel: 'Unknown')] }

    it 'reports it' do
      expect(check.errors).to eq(
        [{ pointer: pointer(0, 'primer_panel'),
           detail: 'No primer panel named Unknown (used by 1 sample)' }]
      )
    end
  end

  context 'with an insert size range the wrong way round' do
    let(:samples) do
      [sample(0, insert_size_from: 300, insert_size_to: 200)]
    end

    it 'reports the end of the range' do
      expect(check.errors).to eq(
        [{ pointer: pointer(0, 'insert_size_to'),
           detail: 'insert_size_to (200) is less than insert_size_from (300)' }]
      )
    end
  end

  context 'with an insert size range of one size' do
    let(:samples) do
      [sample(0, insert_size_from: 200, insert_size_to: 200)]
    end

    it 'finds no errors' do
      expect(check.errors).to be_empty
    end
  end

  context 'with only one end of the insert size range' do
    let(:samples) { [sample(0, insert_size_to: 200)] }

    it 'finds no errors' do
      expect(check.errors).to be_empty
    end
  end

  context 'with the same library type in both fields, in another case' do
    let(:samples) do
      [sample(0, library_type: library_type.name,
                 library_type_long_read: library_type.name.upcase)]
    end

    it 'finds no errors' do
      expect(check.errors).to be_empty
    end
  end

  context 'with different library types in the two fields' do
    let(:other) { create(:library_type) }
    let(:samples) do
      [sample(0, library_type: library_type.name,
                 library_type_long_read: other.name)]
    end

    it 'reports the long read field' do
      expect(check.errors).to eq(
        [{ pointer: pointer(0, 'library_type_long_read'),
           detail: "library_type_long_read (#{other.name}) differs from " \
                   "library_type (#{library_type.name})" }]
      )
    end
  end

  context 'with library types in both fields' do
    let(:samples) do
      [sample(0, library_type: library_type.name),
       sample(1, library_type_long_read: 'Unknown')]
    end

    # Built first, so creating the library type isn't counted
    before { samples }

    it 'looks them up in one query' do
      expect(queries_in { check.errors }.size).to eq(1)
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
