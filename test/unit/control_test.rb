require "test_helper"

class ControlTest < ActiveSupport::TestCase
  context "A control" do
    should_belong_to :pipeline
  end
end
