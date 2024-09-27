# frozen_string_literal: true

require 'rails_helper'

RSpec.describe QcResult, :qc_result do
  it 'is not valid without a key' do
    expect(build(:qc_result, key: nil)).not_to be_valid
  end

  it 'is not valid without a value' do
    expect(build(:qc_result, value: nil)).not_to be_valid
  end

  it 'is not valid without units' do
    expect(build(:qc_result, units: nil)).not_to be_valid
  end

  it 'must have an asset' do
    expect(build(:qc_result, asset: nil)).not_to be_valid
  end

  it 'can have a cv' do
    expect(build(:qc_result).cv).to be_present
  end

  it 'can have an assay type' do
    expect(build(:qc_result).assay_type).to be_present
  end

  it 'can have an assay version' do
    expect(build(:qc_result).assay_version).to be_present
  end

  it '#order_by_date' do
    create(:qc_result, created_at: Date.yesterday)
    create(:qc_result, created_at: Time.zone.today)
    tomorrow = create(:qc_result, created_at: Date.tomorrow)
    expect(described_class.order_by_date.count).to eq(3)
    expect(described_class.order_by_date.first).to eq(tomorrow)
  end

  it '#by_key will return the qc results by key' do
    create(:qc_result_concentration)
    create(:qc_result_molarity)
    create(:qc_result_volume)
    create(:qc_result_rin)
    results = described_class.by_key
    expect(results.size).to eq(4)
    expect(results['concentration'].length).to eq(1)
    expect(results['rin'].length).to eq(1)
  end

  context 'with an asset' do
    let(:asset) { build(:receptacle) }

    it 'can update its asset' do
      expect(asset).to receive(:update_from_qc).with(an_instance_of(described_class))
      create(:qc_result, asset:)
    end
  end
end

describe QcResult, :warren do
  let(:warren) { Warren.handler }

  before { warren.clear_messages }

  let(:resource) { build(:qc_result) }
  let(:routing_key) { 'message.qc_result.' }

  it 'broadcasts the resource' do
    resource.save!
    expect(warren.messages_matching(routing_key)).to eq(1)
  end
end
