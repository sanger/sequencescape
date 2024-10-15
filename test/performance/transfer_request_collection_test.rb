# frozen_string_literal: true

require 'test_helper'
require 'rails/performance_test_help'

class TransferRequestCollectionTest < ActionDispatch::PerformanceTest
  self.profile_options = { runs: 1, metrics: [:wall_time], formats: [:flat] }

  # Refer to the documentation for all available options
  # self.profile_options = { runs: 5, metrics: [:wall_time, :memory],
  #                          output: 'tmp/performance', formats: [:flat] }

  SIZE = 96

  def setup
    ao = { sample: FactoryBot.create(:sample), study: FactoryBot.create(:study), project: FactoryBot.create(:project) }
    asset = FactoryBot.create_list(:untagged_well, SIZE, aliquot_options: ao)
    target_asset = FactoryBot.create_list(:empty_well, SIZE)
    @transfer_requests_attributes =
      Array.new(SIZE) { |i| { source_asset: asset[i].uuid, target_asset: target_asset[i].uuid } }
    @user = FactoryBot.create(:user)
    @api_key = FactoryBot.create(:api_application).key
  end

  # test 'TransferRequestCollection::Create' do
  #   ActiveRecord::Base.transaction do
  #     TransferRequestCollection.create!(user: @user, transfer_requests_attributes: @transfer_requests_attributes)
  #   end
  # end

  test 'api/1/transfer_request_collection' do
    post '/api/1/transfer_request_collection',
         params: {
           transfer_request_collection: {
             user: @user.uuid,
             transfer_requests: @transfer_requests_attributes
           }
         },
         headers: {
           :content_type => 'application/json',
           :accept => 'application/json',
           'HTTP_X_SEQUENCESCAPE_CLIENT_ID' => @api_key
         },
         as: :json
  end
end
