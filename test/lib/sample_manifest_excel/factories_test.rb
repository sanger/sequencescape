require "test_helper"

class FactoryGirlTest < ActiveSupport::TestCase

  test "should build valid factories" do
	assert FactoryGirl.build(:range).valid?
  end

end