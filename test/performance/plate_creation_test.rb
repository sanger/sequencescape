# frozen_string_literal: true

require 'test_helper'
require 'rails/performance_test_help'

class PlateCreationTest < ActionDispatch::PerformanceTest
  self.profile_options = { runs: 5, metrics: [:wall_time], formats: [:flat] }

  # Refer to the documentation for all available options
  # self.profile_options = { runs: 5, metrics: [:wall_time, :memory],
  #                          output: 'tmp/performance', formats: [:flat] }
  SIZE = 6
  def setup
    @purpose = create(:plate_purpose)
  end

  test 'PlatePurpose.create' do
    ActiveRecord::Base.transaction { @purpose.create!(barcode: '12345') }
  end
end
