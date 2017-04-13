# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2015 Genome Research Ltd.

require 'test_helper'

class EventfulEntry < ActiveRecord::Base
  extend EventfulRecord
  has_many_events
  has_many_lab_events

  self.table_name = :requests
end

class EventfulEntryTest < ActiveSupport::TestCase
  context 'A model using events' do
    setup do
      @request_type = create :request_type
      @study = create :study

      @test_subject = EventfulEntry.create(request_type_id: @request_type.id, study_id: @study.id)
      @event        = Event.new(eventful_id: @test_subject.id, eventful_type: @test_subject.class.to_s, family: 'Billing')
      @event.save
      assert @test_subject.valid?
    end
  end
end
