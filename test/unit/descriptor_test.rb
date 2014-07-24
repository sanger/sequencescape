require "test_helper"

class DescriptorTest < ActiveSupport::TestCase
  context "A descriptor" do
    should_belong_to :task
  end
end
