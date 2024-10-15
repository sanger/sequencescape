# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::RequestIo do
  subject { create(:request, asset: source_asset, target_asset: target_asset) }

  context 'between tubes' do
    let(:source_asset) { create(:sample_tube) }
    let(:target_asset) { create(:library_tube) }

    let(:expected_json) do
      {
        'uuid' => subject.uuid,
        'id' => subject.id,
        'state' => subject.state,
        'request_type' => subject.request_type.name,
        'target_asset_uuid' => target_asset.uuid,
        'target_asset_name' => target_asset.name,
        'target_asset_type' => 'library_tubes',
        'target_asset_barcode' => target_asset.barcode_number,
        'target_asset_barcode_prefix' => target_asset.prefix,
        'target_asset_state' => target_asset.qc_state,
        'target_asset_closed' => false,
        'target_asset_two_dimensional_barcode' => target_asset.two_dimensional_barcode,
        'target_asset_sample_uuid' => target_asset.samples.first.uuid,
        'target_asset_sample_internal_id' => target_asset.samples.first.id,
        'source_asset_uuid' => source_asset.uuid,
        'source_asset_name' => source_asset.name,
        'source_asset_type' => 'sample_tubes',
        'source_asset_barcode' => source_asset.barcode_number,
        'source_asset_barcode_prefix' => source_asset.prefix,
        'source_asset_state' => source_asset.qc_state,
        'source_asset_closed' => false,
        'source_asset_two_dimensional_barcode' => source_asset.two_dimensional_barcode,
        'source_asset_sample_uuid' => source_asset.samples.first.uuid,
        'source_asset_sample_internal_id' => source_asset.samples.first.id
      }
    end

    it_behaves_like('an IO object')
  end

  context 'between wells' do
    let(:source_asset) { create(:untagged_well) }
    let(:target_asset) { create(:untagged_well) }

    let(:expected_json) do
      {
        'uuid' => subject.uuid,
        'id' => subject.id,
        'state' => subject.state,
        'request_type' => subject.request_type.name,
        'target_asset_uuid' => target_asset.uuid,
        'target_asset_name' => target_asset.name,
        'target_asset_type' => 'wells',
        'target_asset_state' => target_asset.qc_state,
        'target_asset_closed' => false,
        'target_asset_two_dimensional_barcode' => nil,
        'target_asset_sample_uuid' => target_asset.samples.first.uuid,
        'target_asset_sample_internal_id' => target_asset.samples.first.id,
        'source_asset_uuid' => source_asset.uuid,
        'source_asset_name' => source_asset.name,
        'source_asset_type' => 'wells',
        'source_asset_state' => source_asset.qc_state,
        'source_asset_closed' => false,
        'source_asset_two_dimensional_barcode' => nil,
        'source_asset_sample_uuid' => source_asset.samples.first.uuid,
        'source_asset_sample_internal_id' => source_asset.samples.first.id
      }
    end

    it_behaves_like('an IO object')
  end

  context 'with no target asset' do
    let(:source_asset) { create(:untagged_well) }
    let(:target_asset) { nil }

    let(:expected_json) do
      {
        'uuid' => subject.uuid,
        'id' => subject.id,
        'state' => subject.state,
        'request_type' => subject.request_type.name,
        'source_asset_uuid' => source_asset.uuid,
        'source_asset_name' => source_asset.name,
        'source_asset_type' => 'wells',
        'source_asset_state' => source_asset.qc_state,
        'source_asset_closed' => false,
        'source_asset_two_dimensional_barcode' => nil,
        'source_asset_sample_uuid' => source_asset.samples.first.uuid,
        'source_asset_sample_internal_id' => source_asset.samples.first.id
      }
    end

    it_behaves_like('an IO object')
  end

  context 'with metadata' do
    subject { create(:library_creation_request) }

    let(:expected_json) do
      {
        'uuid' => subject.uuid,
        'id' => subject.id,
        'state' => subject.state,
        'request_type' => subject.request_type.name,
        'fragment_size_required_from' => '100',
        'fragment_size_required_to' => '200',
        'library_type' => 'Standard'
      }
    end

    it_behaves_like('an IO object')
  end
end
