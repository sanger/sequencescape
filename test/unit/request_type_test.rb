require 'test_helper'

class RequestTypeTest < ActiveSupport::TestCase
  context RequestType do
    should have_many :requests
    should validate_presence_of :order
    should validate_presence_of :request_purpose
    should validate_numericality_of :order
  end
end
