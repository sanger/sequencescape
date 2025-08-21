# frozen_string_literal: true

require 'test_helper'

class RequestTest < ActiveSupport::TestCase
  include AASM

  context 'A Request' do
    should belong_to :user
    should belong_to(:request_type).required
    should belong_to :item
    should have_many :events
    should validate_presence_of :request_purpose
    should_have_instance_methods :pending?, :start, :started?, :fail, :failed?, :pass, :passed?, :reset
  end
end
