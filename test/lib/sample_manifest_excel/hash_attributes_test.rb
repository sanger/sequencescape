require 'test_helper'

class HashAttributesTest < ActiveSupport::TestCase
  attr_reader :goose, :options

  class Goose
    include SampleManifestExcel::HashAttributes

    set_attributes :gosling_a, :gosling_b, :gosling_c, :gosling_d, defaults: { gosling_d: 'Consuela' }

    attr_reader :gosling_e

    def initialize(attributes = {})
      create_attributes(attributes)
    end
  end

  def setup
    @options = { gosling_a: 'Bert', gosling_b: 'Ernie', gosling_c: 'Liz', gosling_d: 'Lisa', gosling_e: 'Henry' }
    @goose = Goose.new(gosling_a: 'Bert', gosling_b: 'Ernie', gosling_c: 'Liz', gosling_d: 'Lisa', gosling_e: 'Henry')
  end

  test 'should set included attributes' do
    assert_equal 'Bert', goose.gosling_a
    assert_equal 'Ernie', goose.gosling_b
    assert_equal 'Liz', goose.gosling_c
    assert_equal 'Lisa', goose.gosling_d
  end

  test 'should not set attributes which are not included' do
    refute goose.gosling_e
  end

  test '#attributes should return an array of attribute accessors' do
    assert_equal [:gosling_a, :gosling_b, :gosling_c, :gosling_d], goose.attributes
  end

  test 'should set default attributes' do
    goose = Goose.new
    refute goose.gosling_a
    refute goose.gosling_b
    refute goose.gosling_c
    assert_equal 'Consuela', goose.gosling_d
  end

  test '#update_attributes should not reset default attributes' do
    goose.update_attributes(gosling_a: 'Arnie')
    assert_equal 'Arnie', goose.gosling_a
    assert_equal 'Lisa', goose.gosling_d
  end

  test 'should add attributes irrespective of key type' do
    goose = Goose.new(options.stringify_keys)
    assert_equal 'Bert', goose.gosling_a
    assert_equal 'Ernie', goose.gosling_b
    assert_equal 'Liz', goose.gosling_c
    assert_equal 'Lisa', goose.gosling_d
    refute goose.gosling_e
  end

  test '#to_a should return array of instance variables that have been set' do
    assert_equal %w(Bert Ernie Liz Lisa).sort, goose.to_a.sort
    goose.update_attributes(gosling_a: nil)
    assert_equal ['Ernie', 'Liz', 'Lisa'].sort, goose.to_a.sort
  end

  test 'should be comparable' do
    assert_equal goose, Goose.new(options)
    refute_equal goose, Goose.new(options.except(:gosling_d))
    refute_equal goose, Goose.new(options.merge(gosling_d: 'Ernie'))
    refute_equal Array.new, Goose.new(options)
  end
end
