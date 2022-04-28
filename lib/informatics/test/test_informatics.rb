# frozen_string_literal: true
require 'test/unit'
require 'informatics/support/options'

class TestInformatics < Test::Unit::TestCase # rubocop:todo Style/Documentation
  def setup
    @hash = { 'KEY' => 'VALUE' }
    @o = Informatics::Support::Options.collect(@hash)
  end

  def test_new
    assert_kind_of Informatics::Support::Options, @o
  end

  def test_collect
    assert_equal @hash, @o.options
  end

  def test_first_key
    assert_equal 'KEY', @o.first_key
  end

  def test_first_value
    assert_equal 'VALUE', @o.first_value
  end
end
