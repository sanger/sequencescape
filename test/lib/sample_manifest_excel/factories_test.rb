require "test_helper"

class FactoryGirlTest < ActiveSupport::TestCase

  test "should build valid factories" do
		assert FactoryGirl.build(:range).valid?
		assert FactoryGirl.build(:column).valid?
		assert FactoryGirl.build(:style).valid?
		assert FactoryGirl.build(:validation).valid?
  end

end