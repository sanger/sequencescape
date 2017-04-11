require 'test_helper'

class ConditionalFormattingDefaultListTest < ActiveSupport::TestCase
  include SampleManifestExcel::Helpers

  attr_reader :rules, :yaml, :defaults

  def setup
    folder = File.join('test', 'data', 'sample_manifest_excel', 'extract')
    @rules = load_file(folder, 'conditional_formattings')
    @defaults = SampleManifestExcel::ConditionalFormattingDefaultList.new(rules)
  end

  test 'should have the correct number of defaults' do
    assert_equal rules.length, defaults.count
  end

  test '#find_by should return the correct default' do
    assert defaults.find_by(rules.keys.first)
    assert defaults.find_by(rules.keys.first.to_sym)
  end

  test 'each default should have the correct type' do
    rules.each do |k, _v|
      assert_equal k.to_sym, defaults.find_by(k).type
    end
  end

  test 'should be comparable' do
    assert_equal SampleManifestExcel::ConditionalFormattingDefaultList.new(rules), defaults
    rules.shift
    refute_equal SampleManifestExcel::ConditionalFormattingDefaultList.new(rules), defaults
  end
end
