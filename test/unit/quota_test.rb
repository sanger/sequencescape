require "test_helper"

class QuotaTest < ActiveSupport::TestCase
  context "A quota" do
    should_belong_to :project, :request_type
  end

end
