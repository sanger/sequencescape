require "test_helper"

class EventfulEntry < ActiveRecord::Base
  extend EventfulRecord
  has_many_events
  has_many_lab_events

  set_table_name :requests
end

class EventfulEntryTest < ActiveSupport::TestCase
  context "A model using events" do

    setup do
      @request_type = Factory :request_type
      @study      = Factory :study

      @test_subject = EventfulEntry.create(:request_type_id => @request_type.id, :study_id => @study.id)
      @event        = Event.new({ :eventful_id => @test_subject.id,  :eventful_type => @test_subject.class.to_s, :family => "Billing" })
      @event.save
      assert_valid @test_subject
    end

  end
end

