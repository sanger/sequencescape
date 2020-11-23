require 'rails_helper'

def subject_record(role_type, subject_type, friendly_name, uuid)
  {
    "role_type": role_type,
    "subject_type": subject_type,
    "friendly_name": friendly_name,
    "uuid": uuid
  }
end

RSpec.describe BroadcastEvent::PlateCherrypicked, type: :model, broadcast_event: true do
  let(:plate1) { subject_record('plate', 'cherrypicking_source', '000001', uuids[0]) }
  let(:plate2) { subject_record('plate', 'cherrypicking_source', '000002', uuids[1]) }
  let(:sample1) { subject_record('sample', 'sample', 'ASDF001-000001_A01-AP-Positive', uuids[2]) }
  let(:sample2) { subject_record('plate', 'cherrypicking_source', 'ASDF001-000001_B01-AP-Negative', uuids[3]) }
  let(:robot) { subject_record('robot', 'robot', 'RB00001', uuids[4]) }
  it 'is not directly instantiated' do
    expect(described_class.new).not_to be_valid
  end

  it 'cannot be created without robot' do
    props = {subjects: [plate1, plate2, sample1, sample2]}
    expect(described_class.new(properties: props)).not_to be_valid
  end
  
  it 'cannot be created without source plates' do

    expect(described_class.new).not_to be_valid
  end

  it 'cannot be created without samples' do
    expect(described_class.new).not_to be_valid
  end

  it 'can be created when all required subjects are defined' do
    expect(described_class.new).to be_valid
  end
end