require 'test_helper'

# JG: We really shouldn't need item any more.
class ItemTest < ActiveSupport::TestCase
  context 'An Item' do
    should have_many :requests
    should validate_presence_of :name
  end
end
