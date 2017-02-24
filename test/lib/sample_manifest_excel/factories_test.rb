require 'test_helper'

class FactoryGirlTest < ActiveSupport::TestCase
  Dir[File.join(Rails.root, 'test', 'lib', 'sample_manifest_excel', 'factories', '*.rb')].each do |filename|
    factory = File.basename(filename, File.extname(filename)).singularize

    test "should build valid #{factory} factory" do
      assert FactoryGirl.build(factory.to_sym).valid?
    end
  end
end
