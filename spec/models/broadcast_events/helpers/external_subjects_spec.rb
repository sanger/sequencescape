require 'rails_helper'
#require 'broadcast_event/helpers/external_subjects'

RSpec.describe BroadcastEvent::Helpers::ExternalSubjects do 
  class TestingEvent < BroadcastEvent
    include BroadcastEvent::Helpers::ExternalSubjects
  end

  let(:labware) { create :labware }

  let(:sub1) { 
    {
      "role_type": "sender",
      "subject_type": "person",
      "friendly_name": "alice@example.com",
      "uuid": "00000000-1111-2222-3333-555555555555"
    }
  }
  let(:sub2) {
    {
      "role_type": "recipient",
      "subject_type": "person",
      "friendly_name": "bob@example.com",
      "uuid": "00000000-1111-2222-3333-666666666666"
    }
  }
  let(:sub3) {
    {
      "role_type": "package",
      "subject_type": "plant",
      "friendly_name": "Chuck",
      "uuid": "00000000-1111-2222-3333-777777777777"
    }    
  }
  let(:subjects_definition) {  [ sub1, sub2, sub3 ] }

  let(:instance) { 
    TestingEvent.new(seed: labware, properties: {subjects: subjects_definition }) 
  }
  it 'can instantiate the class' do
    expect(TestingEvent.new(seed: labware)).to be_valid
  end

  it 'returns [] when no subject properties defined' do
    expect(TestingEvent.new(seed: labware).subjects).to eq([])
    expect(TestingEvent.new(seed: labware, properties: {a: 1, b: 2}).subjects).to eq([])
  end

  context '#subjects' do
    it 'returns empty list when empty subjects provided' do
      expect(TestingEvent.new(seed: labware, properties: {subjects: []}).subjects).to eq([])
    end
    it 'returns the properties declared in the properties as subjects' do
      subjects = instance.subjects
      expect(subjects.size).to eq(3)
      expect(subjects[0].role_type).to eq("sender")
      expect(subjects[1].subject_type).to eq("person")
      expect(subjects[1].friendly_name).to eq("bob@example.com")
      expect(subjects[2].friendly_name).to eq("Chuck")
      expect(subjects[2].uuid).to eq("00000000-1111-2222-3333-777777777777")
    end
  end

  context '#subjects_with_role_type' do
    it 'filters subjects by role_type' do
      subs = instance.subjects_with_role_type('sender')
      expect(subs.length).to eq(1)
      expect(subs[0].role_type).to eq('sender')
    end
    it 'filters with subject that does not exist' do
      subs = instance.subjects_with_role_type('bubidibu')
      expect(subs.length).to eq(0)
    end
  end

  context '#has_subjects_with_role_type?' do
    it 'can detect if a role type is present' do
      expect(instance.has_subjects_with_role_type?('sender')).to be_truthy
    end
    it 'can detect if a role type is not present' do
      expect(instance.has_subjects_with_role_type?('bubidu')).to be_falsy
    end

  end

  context '#check_subject_role_type' do
    it 'validates presence of role type' do
      instance.check_subject_role_type(:sender, 'sender')
      expect(instance.errors.size).to eq(0)
    end
    it 'invalidates absence of role type' do
      instance.check_subject_role_type(:sender, 'adsf')
      expect(instance.errors.size).to eq(1)
    end

  end

  context '#build_subjects' do
    it 'can build a new list of subjects' do
      expect(instance.build_subjects.length).to eq(3)
      instance.properties[:subjects].pop
      expect(instance.build_subjects.length).to eq(2)
    end
  end
end