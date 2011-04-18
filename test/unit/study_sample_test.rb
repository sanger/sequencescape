require "test_helper"

class StudySampleTest < ActiveSupport::TestCase
  context "A StudySample" do
    should_belong_to :study
    should_belong_to :sample
  end
end
