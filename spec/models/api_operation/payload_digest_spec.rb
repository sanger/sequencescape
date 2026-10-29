# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApiOperation::PayloadDigest do
  def digest(payload)
    described_class.hexdigest(payload)
  end

  let(:payload) do
    '{"request": {"external_id": "r1"}, "labware": [1, 2], "work_order": {}}'
  end

  it 'returns a 64 character hex digest' do
    expect(digest(payload)).to match(/\A\h{64}\z/)
  end

  it 'returns the same digest for the same payload' do
    expect(digest(payload)).to eq(digest(payload.dup))
  end

  it 'ignores key order at every level' do
    reordered =
      '{"work_order": {}, "labware": [1, 2], "request": {"external_id": "r1"}}'
    expect(digest(reordered)).to eq(digest(payload))
  end

  it 'ignores key order in nested objects' do
    expect(digest('{"a": {"x": 1, "y": 2}}'))
      .to eq(digest('{"a": {"y": 2, "x": 1}}'))
  end

  it 'ignores whitespace' do
    compact = '{"request":{"external_id":"r1"},"labware":[1,2],"work_order":{}}'
    expect(digest(compact)).to eq(digest(payload))
  end

  it 'ignores how a decimal is written' do
    expect(digest('{"a": 1.10}')).to eq(digest('{"a": 1.1}'))
  end

  it 'treats an integer and a decimal as different' do
    expect(digest('{"a": 1}')).not_to eq(digest('{"a": 1.0}'))
  end

  it 'changes when array order changes' do
    swapped =
      '{"request": {"external_id": "r1"}, "labware": [2, 1], "work_order": {}}'
    expect(digest(swapped)).not_to eq(digest(payload))
  end

  it 'changes when a value changes' do
    changed =
      '{"request": {"external_id": "r2"}, "labware": [1, 2], "work_order": {}}'
    expect(digest(changed)).not_to eq(digest(payload))
  end

  it 'raises an error for invalid JSON' do
    expect { digest('{"a": ') }.to raise_error(JSON::ParserError)
  end
end
