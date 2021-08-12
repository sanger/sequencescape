# frozen_string_literal: true

require 'rails_helper'

describe 'TubeCreation endpoints' do
  let(:authorised_app) { create :api_application }
  let(:user) { create :user }

  describe 'Creating a tube' do
    let(:endpoint) { '/api/1/specific_tube_creations' }

    let(:parent_plate) { create :plate, well_count: 5 }
    let!(:stock_plate) { create :full_stock_plate, well_count: parent_plate.wells.count }
    let!(:submission) { Submission.create!(user: user) }

    let(:child_purpose) { create :tube_purpose }

    before do
      AssetLink.create!(ancestor: stock_plate, descendant: parent_plate)

      parent_plate
        .wells
        .in_column_major_order
        .readonly(false)
        .each_with_index do |well, i|
          stock_well = stock_plate.wells[i]
          FactoryBot.create(:library_creation_request, asset: stock_well, target_asset: well, submission: submission)
          FactoryBot.create(:transfer_request, asset: stock_well, target_asset: well, submission: submission)
          well.stock_wells.attach!([stock_well])
        end
    end

    context 'when the payload has all the required information' do
      # rubocop:disable Metrics/MethodLength
      def construct_expected_response_body(parent_plate, new_tube_creation)
        "{
          \"specific_tube_creation\": {
            \"actions\": {
              \"read\": \"http://www.example.com/api/1/#{new_tube_creation.uuid}\"
            },
            \"parent\": {
              \"actions\": {
                \"read\": \"http://www.example.com/api/1/#{parent_plate.uuid}\"
              }
            },
            \"child_purposes\": {
              \"actions\": {
                \"read\": \"http://www.example.com/api/1/#{new_tube_creation.uuid}/child_purposes\"
              }
            },
            \"children\": {
              \"actions\": {
                \"read\": \"http://www.example.com/api/1/#{new_tube_creation.uuid}/children\"
              },
              \"size\": 1
            },

            \"uuid\": \"#{new_tube_creation.uuid}\"
          }
        }"
      end

      # rubocop:enable Metrics/MethodLength

      let(:payload) do
        "{
          \"specific_tube_creation\":{
            \"user\": \"#{user.uuid}\",
            \"parent\":\"#{parent_plate.uuid}\",
            \"child_purposes\":[\"#{child_purpose.uuid}\"]
          }
        }"
      end

      let(:response_code) { 201 }

      it 'is successful' do
        api_request :post, endpoint, payload

        new_tube_creation = SpecificTubeCreation.last
        response_body = construct_expected_response_body(parent_plate, new_tube_creation)

        expect(JSON.parse(response.body)).to include_json(JSON.parse(response_body))
        expect(status).to eq(response_code)
      end

      describe 'Retrieving a Tube Creation' do
        let!(:tube_creation) do
          SpecificTubeCreation.create!(user: user, parent: parent_plate, child_purposes: [child_purpose])
        end

        let(:response_code) { 200 }

        it 'is successful' do
          api_request :get, "/api/1/#{tube_creation.uuid}"

          expected_json_body = construct_expected_response_body(parent_plate, child_purpose, tube_creation)
          expect(JSON.parse(response.body)).to include_json(JSON.parse(expected_json_body))
          expect(status).to eq(response_code)
        end
      end
    end

    # context 'when the tube has multiple parents' do
    #   def construct_expected_response_body(parents, child_purpose, new_tube_creation)
    #     # binding.pry
    #     "{
    #       \"tube_creation\": {
    #         \"actions\": {
    #           \"read\": \"http://www.example.com/api/1/#{new_tube_creation.uuid}\"
    #         },
    #         \"parents\": {
    #           \"actions\": {
    #             \"read\": \"http://www.example.com/api/1/#{parents[0].uuid}\",
    #             \"read\": \"http://www.example.com/api/1/#{parents[1].uuid}\",
    #           }
    #         },
    #         \"child_purpose\": {
    #           \"actions\": {
    #             \"read\": \"http://www.example.com/api/1/#{child_purpose.uuid}\"
    #           }
    #         },
    #         \"children\": {
    #           \"actions\": {
    #             \"read\": \"http://www.example.com/api/1/#{new_tube_creation.uuid}/children\"
    #           },
    #           \"size\": 1
    #         },

    #         \"uuid\": \"#{new_tube_creation.uuid}\"
    #       }
    #     }"
    #   end

    #   let!(:parent_tube) { create :tube }
    #   let(:payload) do
    #     "{
    #       \"tube_creation\":{
    #         \"user\": \"#{user.uuid}\",
    #         \"parents\":\"[#{parent_plate.uuid}, #{parent_tube.uuid}]\",
    #         \"child_purpose\":\"#{child_purpose.uuid}\"
    #       }
    #     }"
    #   end

    #   let(:response_code) { 201 }

    #   it 'is successful' do
    #     api_request :post, endpoint, payload
    #     puts "*** response body: #{response.body} ***"
    #     new_tube_creation = TubeCreation.last
    #     response_body = construct_expected_response_body([parent_plate, parent_tube], child_purpose, new_tube_creation)
    #     # expect(JSON.parse(response.body)).to include_json(JSON.parse(response_body))
    #     expect(status).to eq(response_code)
    #   end
    # end
  end
end
