require "test_helper"

class PermissionTest < ActiveSupport::TestCase
  context "A property definition" do
    should_belong_to :permissable
  end
end
