# frozen_string_literal: true

require 'test_helper'
require 'rails/performance_test_help'

class StateChangeTest < ActionDispatch::PerformanceTest
  self.profile_options = { runs: 5, metrics: [:wall_time], formats: [:flat] }

  # Refer to the documentation for all available options
  # self.profile_options = { runs: 5, metrics: [:wall_time, :memory],
  #                          output: 'tmp/performance', formats: [:flat] }
  def setup
    @source = create(:transfer_plate, well_count: 96)
    @destination = create(:plate, well_count: 96)
    transfers = @source.wells.each_with_object({}) { |w, h| h[w.map_description] = w.map_description }
    @transfer = create(:transfer_between_plates, source: @source, destination: @destination, transfers: transfers)
    @user = create(:user)
  end

  test 'StateChange.create' do
    ActiveRecord::Base.transaction { StateChange.create!(target: @destination, user: @user, target_state: 'passed') }
  end
end
