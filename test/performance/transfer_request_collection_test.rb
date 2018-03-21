require 'test_helper'
require 'rails/performance_test_help'

class TransferRequestCollectionTest < ActionDispatch::PerformanceTest
  self.profile_options = { runs: 1, metrics: [:wall_time], formats: [:flat] }
  # Refer to the documentation for all available options
  # self.profile_options = { runs: 5, metrics: [:wall_time, :memory],
  #                          output: 'tmp/performance', formats: [:flat] }

  SIZE = 6

  def setup
    ao = {
      sample: FactoryGirl.create(:sample),
      study: FactoryGirl.create(:study),
      project: FactoryGirl.create(:project)
    }
    asset = FactoryGirl.create_list(:untagged_well, SIZE, aliquot_options: ao)
    target_asset = FactoryGirl.create_list(:empty_well, SIZE)
    @transfer_requests_attributes = Array.new(SIZE) do |i|
      { asset_id: asset[i].id, target_asset_id: target_asset[i].id }
    end
    @user = FactoryGirl.create :user
  end

  test 'TransferRequestCollection::Create' do
    ActiveRecord::Base.transaction do
      TransferRequestCollection.create!(user: @user, transfer_requests_attributes: @transfer_requests_attributes)
    end
  end
end
