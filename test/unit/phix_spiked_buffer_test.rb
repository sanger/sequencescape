# frozen_string_literal: true
require 'test_helper'

class PhixSpikedBufferTest < ActiveSupport::TestCase
  context 'PhiX Factory Test' do
    setup do
      @phi_x_spiked_buffer = FactoryBot.create(:phi_x_spiked_buffer)
    end

    should 'create a PhiX Stock' do
      assert @phi_x_spiked_buffer.valid?
    end
  end
end