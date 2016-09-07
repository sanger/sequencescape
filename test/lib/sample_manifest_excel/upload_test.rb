require "test_helper"

class UploadTest < ActiveSupport::TestCase

  context "Headings" do

    attr_reader :column_list, :dodgy_column

    setup do
      @column_list = build(:column_list, 5)
      @dodgy_column = build(:column)
    end

    # test "should be valid if all of the headings relate to a column" do
    #   headings = 

    # end

    # test "should be invalid if any of the headings do not relate to a column" do
    # end
  end
    
end