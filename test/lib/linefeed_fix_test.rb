# frozen_string_literal: true

require_relative '../test_helper'
require './lib/linefeed_fix'

class LinefeedFixTest < ActiveSupport::TestCase
  context 'LinefeedFix' do
    setup { Rails.root.join("test/data/bad.csv").open { |f| @string = f.read } }

    should 'raise if we don\'t do anything' do
      # Makes sure sublime hasn't 'fixed' the file for us
      assert_equal "Example,colB\r\r\nUnparse,eg\r\r\n", @string
    end

    should 'return a readable string' do
      assert_equal "Example,colB\nUnparse,eg\n", LinefeedFix.scrub!(@string)

      # And just double check that we've generated a valid csv
      assert_equal [%w[Example colB], %w[Unparse eg]], CSV.parse(@string)
    end
  end
end
