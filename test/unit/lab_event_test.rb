
require 'test_helper'

class LabEventTest < ActiveSupport::TestCase
  context 'An event' do
    should belong_to :user
    should belong_to :eventful
  end
end
