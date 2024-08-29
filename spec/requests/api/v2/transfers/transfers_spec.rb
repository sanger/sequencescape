# frozen_string_literal: true

require 'rails_helper'
require './spec/requests/api/v2/shared_examples/api_key_authenticatable'

describe 'Transfer API', with: :api_v2 do
  let(:base_endpoint) { '/api/v2/transfers/transfers' }

  it_behaves_like 'ApiKeyAuthenticatable'

  context 'with a list of Transfers' do
    let!(:transfers) { create_list(:transfer_between_plates, 5) }

    describe '#get all Transfers' do
      before { api_get base_endpoint }

      it 'responds with a success http code' do
        expect(response).to have_http_status(:success)
      end

      it 'returns the full list of Transfers' do
        expect(json['data'].length).to eq(5)
      end
    end

    describe '#get Transfer by ID' do
      let(:transfer) { transfers.first }

      before { api_get "#{base_endpoint}/#{transfer.id}" }

      it 'responds with a success http code' do
        expect(response).to have_http_status(:success)
      end

      it 'returns the Transfer' do
        expect(json.dig('data', 'id')).to eq(transfer.id.to_s)
        expect(json.dig('data', 'type')).to eq('between_plates')
        expect(json.dig('data', 'attributes', 'uuid')).to eq(transfer.uuid)
        expect(json.dig('data', 'attributes', 'user_uuid')).to eq(transfer.user.uuid)
        expect(json.dig('data', 'attributes', 'source_uuid')).to eq(transfer.source.uuid)
        expect(json.dig('data', 'attributes', 'destination_uuid')).to eq(transfer.destination.uuid)
        expect(json.dig('data', 'attributes', 'transfers')).to eq(transfer.transfers)

        # We don't want to see the TransferTemplate UUID as it's not fetchable.
        expect(json.dig('data', 'attributes', 'transfer_template_uuid')).not_to be_present
      end
    end
  end

  describe '#patch a Transfer' do
    let(:resource_model) { create(:transfer_between_plates) }
    let(:payload) do
      {
        'data' => {
          'id' => resource_model.id,
          'type' => 'transfers',
          'attributes' => {
            'user_uuid' => '111111-2222-3333-4444-555555666666'
          }
        }
      }
    end

    it 'finds no route for the method' do
      expect { api_patch "#{base_endpoint}/#{resource_model.id}", payload }.to raise_error(
        ActionController::RoutingError
      )
    end
  end

  describe '#post a new Transfer' do
    let(:user) { create(:user) }
    let(:source) { create(:transfer_plate) }
    let(:destination) { create(:plate_with_empty_wells) }
    let(:transfer_template) { create(:transfer_template) } # BetweenPlates

    context 'with a valid payload' do
      let(:payload) do
        {
          'data' => {
            'type' => 'transfers',
            'attributes' => {
              user_uuid: user.uuid,
              source_uuid: source.uuid,
              destination_uuid: destination.uuid,
              transfer_template_uuid: transfer_template.uuid
            }
          }
        }
      end

      it 'creates a new resource' do
        expect { api_post base_endpoint, payload }.to change(Transfer::BetweenPlates, :count).by(1)
      end

      it 'responds with success' do
        api_post base_endpoint, payload

        expect(response).to have_http_status(:success)
      end

      it 'responds with the correct attributes' do
        api_post base_endpoint, payload

        expect(json.dig('data', 'type')).to eq('transfers')
        expect(json.dig('data', 'attributes', 'uuid')).to be_present
        expect(json.dig('data', 'attributes', 'user_uuid')).to eq(user.uuid)
        expect(json.dig('data', 'attributes', 'source_uuid')).to eq(source.uuid)
        expect(json.dig('data', 'attributes', 'destination_uuid')).to eq(destination.uuid)
        expect(json.dig('data', 'attributes', 'transfers')).to eq(transfer_template.transfers)
      end
    end

    context 'when providing an invalid payload' do
      shared_examples 'it must not contain that attribute' do
        let(:payload) do
          {
            'data' => {
              'type' => 'transfers',
              'attributes' => {
                user_uuid: user.uuid,
                source_uuid: source.uuid,
                destination_uuid: destination.uuid,
                transfer_template_uuid: transfer_template.uuid,
                "#{disallowed_attribute}": 'Dummy value'
              }
            }
          }
        end

        it 'does not change the number of Transfers' do
          expect { api_post base_endpoint, payload }.not_to change(Transfer::BetweenPlates, :count)
        end

        it 'responds with bad request' do
          api_post base_endpoint, payload

          expect(response).to have_http_status(:bad_request)
        end

        it 'gives an informative error message' do
          api_post base_endpoint, payload

          expect(json.dig('errors', 0, 'detail')).to eq("#{disallowed_attribute} is not allowed.")
        end
      end

      context 'with "uuid"' do
        let(:disallowed_attribute) { 'uuid' }

        it_behaves_like 'it must not contain that attribute'
      end

      shared_examples 'it must include that attribute' do
        let(:payload) do
          {
            'data' => {
              'type' => 'transfers',
              'attributes' => {
                user_uuid: user.uuid,
                source_uuid: source.uuid,
                destination_uuid: destination.uuid,
                transfer_template_uuid: transfer_template.uuid
              }
            }
          }
        end

        before { payload['data']['attributes'].delete(required_attribute) }

        it 'does not change the number of Transfers' do
          expect { api_post base_endpoint, payload }.not_to change(Transfer::BetweenPlates, :count)
        end

        it 'responds with unprocessable entity' do
          api_post base_endpoint, payload

          expect(response).to have_http_status(:unprocessable_entity)
        end

        it 'gives an informative error message' do
          api_post base_endpoint, payload

          expect(json.dig('errors', 0, 'detail')).to eq("#{required_model_field} - can't be blank")
        end
      end

      context 'without "user_uuid"' do
        let(:required_attribute) { :user_uuid }
        let(:required_model_field) { 'user' }

        it_behaves_like 'it must include that attribute'
      end

      context 'without "source_uuid"' do
        let(:required_attribute) { :source_uuid }
        let(:required_model_field) { 'source' }

        it_behaves_like 'it must include that attribute'
      end

      context 'without "destination_uuid"' do
        let(:required_attribute) { :destination_uuid }
        let(:required_model_field) { 'destination' }

        it_behaves_like 'it must include that attribute'
      end

      context 'without "transfer_template_uuid"' do
        let(:payload) do
          {
            'data' => {
              'type' => 'transfers',
              'attributes' => {
                user_uuid: user.uuid,
                source_uuid: source.uuid,
                destination_uuid: destination.uuid
              }
            }
          }
        end

        it 'does not change the number of Transfers' do
          expect { api_post base_endpoint, payload }.not_to change(Transfer::BetweenPlates, :count)
        end

        it 'responds with server error' do
          api_post base_endpoint, payload

          expect(response).to have_http_status(:server_error)
        end

        it 'gives an informative error message' do
          api_post base_endpoint, payload

          expect(json.dig('errors', 0, 'detail')).to eq('Internal Server Error')
        end
      end
    end
  end
end
