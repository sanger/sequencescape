# frozen_string_literal: true

require 'test_helper'

class EventfulEntry < ApplicationRecord
  extend EventfulRecord

  has_many_events
  has_many_lab_events

  self.table_name = :requests
end

class EventfulEntryTest < ActiveSupport::TestCase
  context 'A model using events' do
    setup do
      @request_type = create(:request_type)
      @study = create(:study)

      @test_subject = EventfulEntry.create(request_type_id: @request_type.id, study_id: @study.id)
      @event = Event.new(eventful_id: @test_subject.id, eventful_type: @test_subject.class.to_s, family: 'Billing')
      @event.save

      assert_predicate @test_subject, :valid?
    end
  end
end
