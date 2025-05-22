# frozen_string_literal: true

require "#{File.dirname(__FILE__)}/../test_helper"

class QcFileTest < ActiveSupport::TestCase
  context QcFile do
    context 'with an asset' do
      setup do
        @plate = create(:plate)
        @parser = Object.new
        Parsers.expects(:parser_for).returns(@parser)
      end

      should 'uses the parser to update the values of a well' do
        @plate.expects(:update_qc_values_with_parser).with(@parser)
        QcFile.create!(asset: @plate, uploaded_data: Tempfile.new)
      end
    end
  end
end
