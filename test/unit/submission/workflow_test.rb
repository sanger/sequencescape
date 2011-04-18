require "test_helper"

class Submission::WorkflowTest < ActiveSupport::TestCase
  context "A Workflow" do
    should_have_many :submissions
  end
end
