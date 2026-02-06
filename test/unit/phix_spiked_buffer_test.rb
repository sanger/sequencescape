# frozen_string_literal: true
require 'test_helper'

# TODO: Remove this file before the final release.
# This file is merely a minitest used to ease the debugging purposes.
# It is not a part of the final release.
class PhiXSpikedBufferTest < ActiveSupport::TestCase
  context 'PhiX Factory Test' do
    setup { @phi_x_spiked_buffer = FactoryBot.create(:phi_x_spiked_buffer) }

    should 'create a PhiX Stock' do
      assert_predicate @phi_x_spiked_buffer, :valid?
    end

    should 'Have 1 items in created spiked buffers' do
      assert_equal 1, @phi_x_spiked_buffer.created_spiked_buffers.count
    end

    should 'set correct concentration and volume' do
      assert_equal '9.2', @phi_x_spiked_buffer.concentration
      assert_equal '10.0', @phi_x_spiked_buffer.volume
    end

    should 'have aliquots in each tube' do
      @phi_x_spiked_buffer.created_spiked_buffers.each { |tube| assert_equal 1, tube.aliquots.count }
    end
  end
end
