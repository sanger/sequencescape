require "test_helper"

class LabEventTest < ActiveSupport::TestCase
  context "An event" do
    should_belong_to :user, :eventful
  end
end
