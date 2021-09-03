# frozen_string_literal: true
require 'rails_helper'

RSpec.describe BroadcastEvent::Helpers::ExternalSubjects, heron_events: true do
  let(:testing_event_class) { Class.new(BroadcastEvent) { include BroadcastEvent::Helpers::ExternalSubjects } }
  let(:labware) { create :labware }
  let(:sub1) do
    {
      role_type: 'sender',
      subject_type: 'person',
      friendly_name: 'alice@example.com',
      uuid: '00000000-1111-2222-3333-555555555555'
    }
  end
  let(:sub2) do
    {
      role_type: 'recipient',
      subject_type: 'person',
      friendly_name: 'bob@example.com',
      uuid: '00000000-1111-2222-3333-666666666666'
    }
  end
  let(:sub3) do
    {
      role_type: 'package',
      subject_type: 'plant',
      friendly_name: 'Chuck',
      uuid: '00000000-1111-2222-3333-777777777777'
    }
  end
  let(:subjects_definition) { [sub1, sub2, sub3] }
  let(:instance) { testing_event_class.new(seed: labware, properties: { subjects: subjects_definition }) }

  before { stub_const('TestingClass', testing_event_class) }

  it 'can instantiate the class' do
    inst = testing_event_class.new(seed: labware)
    expect(inst).to be_valid
  end

  it 'returns [] when no subject properties defined' do
    expect(testing_event_class.new(seed: labware).subjects).to eq([])
    expect(testing_event_class.new(seed: labware, properties: { a: 1, b: 2 }).subjects).to eq([])
  end

  describe '#subjects' do
    it 'returns empty list when empty subjects provided' do
      expect(testing_event_class.new(seed: labware, properties: { subjects: [] }).subjects).to eq([])
    end

    it 'returns the properties declared in the properties as subjects' do
      subjects = instance.subjects
      expect(subjects.size).to eq(3)
      expect(subjects[0].role_type).to eq('sender')
      expect(subjects[2].friendly_name).to eq('Chuck')
      expect(subjects[2].uuid).to eq('00000000-1111-2222-3333-777777777777')
    end
  end

  describe '#subjects_with_role_type' do
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

  describe '#subjects_with_role_type?' do
    it 'can detect if a role type is present' do
      expect(instance).to be_subjects_with_role_type('sender')

      # can detect if a role type is not present
      expect(instance).not_to be_subjects_with_role_type('bubidu')
    end
  end

  describe '#check_subject_role_type' do
    it 'validates presence of role type' do
      instance.check_subject_role_type(:sender, 'sender')
      expect(instance.errors.size).to eq(0)
    end

    it 'invalidates absence of role type' do
      instance.check_subject_role_type(:sender, 'adsf')
      expect(instance.errors.size).to eq(1)
    end
  end

  describe '#build_subjects' do
    it 'can build a new list of subjects' do
      expect(instance.build_subjects.length).to eq(3)
      instance.properties[:subjects].pop
      expect(instance.build_subjects.length).to eq(2)
    end
  end
end
