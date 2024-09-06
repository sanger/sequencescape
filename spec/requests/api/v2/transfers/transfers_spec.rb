# frozen_string_literal: true

require 'rails_helper'
require './spec/requests/api/v2/shared_examples/api_key_authenticatable'
require './spec/requests/api/v2/shared_examples/post_requests'

describe 'Transfer API', with: :api_v2 do
  let(:base_endpoint) { '/api/v2/transfers/transfers' }
  let(:model_class) { Transfer::BetweenPlates }

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
    let(:base_attributes) do
      {
        user_uuid: user.uuid,
        source_uuid: source.uuid,
        destination_uuid: destination.uuid,
        transfer_template_uuid: transfer_template.uuid
      }
    end

    context 'with a valid payload' do
      let(:payload) { { 'data' => { 'type' => 'transfers', 'attributes' => base_attributes } } }

      it 'creates a new resource' do
        expect { api_post base_endpoint, payload }.to change(model_class, :count).by(1)
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

    context 'with a read-only attribute in the payload' do
      context 'with uuid' do
        let(:disallowed_attribute) { 'uuid' }
        let(:payload) do
          {
            'data' => {
              'type' => 'transfers',
              'attributes' => base_attributes.merge({ 'uuid' => '111111-2222-3333-4444-555555666666' })
            }
          }
        end

        it_behaves_like 'a POST request with a disallowed attribute'
      end
    end

    context 'without a required attribute' do
      let(:payload) do
        { 'data' => { 'type' => 'transfers', 'attributes' => base_attributes.merge({ attribute_to_remove => nil }) } }
      end

      context 'without user_uuid' do
        let(:attribute_to_remove) { 'user_uuid' }
        let(:error_detail_message) { "user - can't be blank" }

        it_behaves_like 'a POST request with a missing attribute'
      end

      context 'without source_uuid' do
        let(:attribute_to_remove) { 'source_uuid' }
        let(:error_detail_message) { "source - can't be blank" }

        it_behaves_like 'a POST request with a missing attribute'
      end

      context 'without destination_uuid' do
        let(:attribute_to_remove) { 'destination_uuid' }
        let(:error_detail_message) { "destination - can't be blank" }

        it_behaves_like 'a POST request with a missing attribute'
      end
    end

    context 'when providing an invalid payload' do
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
          expect { api_post base_endpoint, payload }.not_to change(model_class, :count)
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
