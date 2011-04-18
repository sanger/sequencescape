require "test_helper"

class FailureTest < ActiveSupport::TestCase
  context "A failure" do
    should_belong_to :failable
  end
end
