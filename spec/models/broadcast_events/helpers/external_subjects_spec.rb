require 'rails_helper'
#require 'broadcast_event/helpers/external_subjects'

RSpec.describe BroadcastEvent::Helpers::ExternalSubjects do 
  class TestingEvent < BroadcastEvent
    include BroadcastEvent::Helpers::ExternalSubjects
  end

  let(:labware) { create :labware }

  it 'can instantiate the class' do
    expect(TestingEvent.new(seed: labware)).to be_valid
  end

  it 'returns [] when no subject properties defined' do
    expect(TestingEvent.new(seed: labware).subjects).to eq([])
    expect(TestingEvent.new(seed: labware, properties: {a: 1, b: 2}).subjects).to eq([])
  end

  context 'with a list of external subjects' do
    let(:subjects_definition) { 
      [
        {
          "role_type": "sender",
          "subject_type": "person",
          "friendly_name": "alice@example.com",
          "uuid": "00000000-1111-2222-3333-555555555555"
        },
        {
          "role_type": "recipient",
          "subject_type": "person",
          "friendly_name": "bob@example.com",
          "uuid": "00000000-1111-2222-3333-666666666666"
        },
        {
          "role_type": "package",
          "subject_type": "plant",
          "friendly_name": "Chuck",
          "uuid": "00000000-1111-2222-3333-777777777777"
        }
      ]
    }
    it 'returns the properties declared in the properties as subjects' do
      expect(TestingEvent.new(seed: labware, properties: {subjects: []}).subjects).to eq([])
      subjects = TestingEvent.new(seed: labware, properties: {subjects: subjects_definition }).subjects
      expect(subjects.size).to eq(3)
      expect(subjects[0].role_type).to eq("sender")
      expect(subjects[1].subject_type).to eq("person")
      expect(subjects[1].friendly_name).to eq("bob@example.com")
      expect(subjects[2].friendly_name).to eq("Chuck")
      expect(subjects[2].uuid).to eq("00000000-1111-2222-3333-777777777777")
    end
  end
end