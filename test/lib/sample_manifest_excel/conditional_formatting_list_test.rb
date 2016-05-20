require 'test_helper'

class ConditionalFormattingListTest < ActiveSupport::TestCase

  attr_reader :conditional_formatting_list, :options

  def setup
    @options = YAML::load_file(File.expand_path(File.join(Rails.root,"test","data", "sample_manifest_excel","conditional_formatting.yml")))
    @conditional_formatting_list = SampleManifestExcel::ConditionalFormattingList.new(options)
  end

  test "it should have the correct number of options" do
    assert_equal options.length, conditional_formatting_list.count
  end


end
