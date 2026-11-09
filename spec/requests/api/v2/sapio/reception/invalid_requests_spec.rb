# frozen_string_literal: true

require 'rails_helper'
require 'shared_contexts/sapio_reception_shared_context'

# Sapio reception from end to end, for requests the reception rejects: the
# operation fails with each problem's pointer and detail, for Integration
# Hub, and nothing is created. How these specs work:
# spec/shared_contexts/sapio_reception_shared_context.rb
describe 'Sapio reception of invalid requests',
         :sapio_operations_endpoint_enabled, :sapio_reception_enabled do
  include_context 'with Sapio reception'

  # The pointer of the only sample in the request's first labware
  let(:sample_pointer) { '/labware/0/receptacles/0/samples/0' }

  # The error details reception records for one problem
  def reception_error(pointer, detail)
    { 'task' => 'reception',
      'errors' => [{ 'pointer' => pointer, 'detail' => detail }] }
  end

  # A first request received the plate; a second gives it other contents,
  # and a new tube
  context 'with known labware whose contents differ' do
    before do
      post_and_process(reception_request(plate('SAPIO-PLATE-1',
                                               'A1' => payload_sample)))
    end

    # The plate's sample, as the first request gave it
    let(:payload_sample) { sample('SAPIO-1-1') }

    # The sample again, with another supplier sample name: what
    # reconciliation compares
    let!(:operation) do
      renamed = payload_sample.merge(supplier_sample_name: 'Other name')
      post_and_process(
        reception_request(plate('SAPIO-PLATE-1', 'A1' => renamed),
                          tube('SAPIO-TUBE-1', sample('SAPIO-2-2')))
      )
    end

    it 'fails the reception' do
      expect(operation.reload.status).to eq('reception_failed')
    end

    it 'records the run of the reception' do
      expect(operation.events.pluck(:task, :outcome))
        .to eq([%w[reception started], %w[reception failed]])
    end

    it 'records the conflict, with its pointer' do
      expect(operation.reload.error_details).to eq(
        reception_error('/labware/0/receptacles/0',
                        'well A1 of SAPIO-PLATE-1 has different supplier ' \
                        'sample names in Sequencescape')
      )
    end

    it 'creates nothing, not even the new tube' do
      expect([Labware.count, Sample.count]).to eq([1, 1])
    end
  end

  context 'with a sample of an unknown study' do
    before do
      allow(ApiOperation::Reception::Creation).to receive(:new)
        .and_call_original
    end

    let(:unknown_study_uuid) { SecureRandom.uuid }
    let!(:operation) do
      payload_sample = sample('SAPIO-1-1', study_uuid: unknown_study_uuid)
      post_and_process(reception_request(plate('SAPIO-PLATE-1',
                                               'A1' => payload_sample)))
    end

    it 'fails the reception' do
      expect(operation.reload.status).to eq('reception_failed')
    end

    it 'records the error, with its pointer' do
      expect(operation.reload.error_details).to eq(
        reception_error("#{sample_pointer}/study_uuid",
                        "No study with UUID #{unknown_study_uuid} " \
                        '(used by 1 sample)')
      )
    end

    it 'does not start creating' do
      expect(ApiOperation::Reception::Creation).not_to have_received(:new)
    end

    it 'creates nothing' do
      expect([Labware.count, Sample.count]).to eq([0, 0])
    end
  end

  context 'with a sample whose UUID Sequencescape already uses' do
    let(:existing_sample) { create(:sample) }
    let!(:operation) do
      payload_sample = sample('SAPIO-1-1', uuid: existing_sample.uuid)
      post_and_process(reception_request(plate('SAPIO-PLATE-1',
                                               'A1' => payload_sample)))
    end

    it 'fails the reception' do
      expect(operation.reload.status).to eq('reception_failed')
    end

    it 'records the error, with its pointer' do
      expect(operation.reload.error_details).to eq(
        reception_error("#{sample_pointer}/uuid",
                        "UUID #{existing_sample.uuid} is already used in " \
                        'Sequencescape')
      )
    end

    it 'creates nothing' do
      expect([Labware.count, Sample.count]).to eq([0, 1])
    end
  end

  context 'with a tag index that its tag group does not have' do
    let(:tag_group) { create(:tag_group_with_tags, tag_count: 2) }
    let!(:operation) do
      payload_sample = sample('SAPIO-1-1', tag_group: tag_group.name,
                                           tag_index: 3)
      post_and_process(reception_request(plate('SAPIO-PLATE-1',
                                               'A1' => payload_sample)))
    end

    it 'fails the reception' do
      expect(operation.reload.status).to eq('reception_failed')
    end

    it 'records the error, with its pointer' do
      expect(operation.reload.error_details).to eq(
        reception_error("#{sample_pointer}/tag_index",
                        "Tag group #{tag_group.name} has no tag with index " \
                        '3 (used by 1 sample)')
      )
    end

    it 'creates nothing' do
      expect([Labware.count, Sample.count]).to eq([0, 0])
    end
  end

  context 'with an unknown reference genome' do
    let!(:operation) do
      payload_sample = sample('SAPIO-1-1',
                              reference_genome: 'Genus species (v0)')
      post_and_process(reception_request(plate('SAPIO-PLATE-1',
                                               'A1' => payload_sample)))
    end

    it 'fails the reception' do
      expect(operation.reload.status).to eq('reception_failed')
    end

    it 'records the error, with its pointer' do
      expect(operation.reload.error_details).to eq(
        reception_error("#{sample_pointer}/reference_genome",
                        'No reference genome named Genus species (v0) ' \
                        '(used by 1 sample)')
      )
    end

    it 'creates nothing' do
      expect([Labware.count, Sample.count]).to eq([0, 0])
    end
  end

  # A sample in two pools has nowhere to keep a volume: not its pooled
  # wells, nor its metadata, as it has two entries
  context 'with a sample in two pools that gives a volume' do
    let(:pooled_sample) { sample('SAPIO-1-1') }
    let(:other_sample) { sample('SAPIO-2-2') }
    let(:detail) do
      "Sample #{pooled_sample[:uuid]} gives a volume that can't be stored: " \
        'it is in more than one receptacle, and this one holds other samples'
    end
    let!(:operation) do
      pools = { 'A1' => [pooled_sample.merge(volume: 10), other_sample],
                'B1' => [pooled_sample, other_sample] }
      post_and_process(reception_request(plate('SAPIO-PLATE-1', pools)))
    end

    it 'fails the reception' do
      expect(operation.reload.status).to eq('reception_failed')
    end

    it 'records the error, with its pointer' do
      expect(operation.reload.error_details)
        .to eq(reception_error(sample_pointer, detail))
    end

    it 'creates nothing' do
      expect([Labware.count, Sample.count]).to eq([0, 0])
    end
  end
end
