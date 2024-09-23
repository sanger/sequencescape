# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TransferRequestCollection, :transfer_request_collection do
  subject { described_class.new(creation_attributes) }

  let(:user) { create :user }
  let(:asset) { create :tagged_well }
  let(:target_asset) { create :empty_library_tube }

  context 'with a single transfer' do
    let(:creation_attributes) do
      { user:, transfer_requests_attributes: [{ asset:, target_asset: }] }
    end

    context 'and no outer requests' do
      describe '#save' do
        let(:transfer_request) { subject.transfer_requests.first }

        before { expect(subject.save).to be true }

        it 'creates a transfer request' do
          expect(subject.transfer_requests.count).to eq(1)
        end

        it 'sets the expected asset' do
          expect(transfer_request.asset).to eq(asset)
        end

        it 'sets the expected target_asset' do
          expect(transfer_request.target_asset).to eq(target_asset.receptacle)
        end
      end
    end

    context 'and one outer request' do
      let(:submission) { create :submission }
      let!(:outer_request) { create :request, asset:, submission: }

      describe '#save' do
        let(:transfer_request) { subject.transfer_requests.first }

        before { expect(subject.save).to be true }

        it 'creates a transfer request' do
          expect(subject.transfer_requests.count).to eq(1)
        end

        it 'sets the expected asset' do
          expect(transfer_request.asset).to eq(asset)
        end

        it 'sets the expected target_asset' do
          expect(transfer_request.target_asset).to eq(target_asset.receptacle)
        end
      end
    end

    context 'and two outer requests' do
      let(:submission_a) { create :submission }
      let(:submission_b) { create :submission }
      let!(:outer_request) { create :request, asset:, submission: submission_a }
      let!(:other_outer_request) { create :request, asset:, submission: submission_b }

      describe '#save' do
        let(:transfer_request) { subject.transfer_requests.first }

        context 'specifying submission' do
          let(:creation_attributes) do
            {
              user:,
              transfer_requests_attributes: [
                { asset:, target_asset:, submission: outer_request.submission }
              ]
            }
          end

          before { expect(subject.save).to be true }

          it 'creates a transfer request' do
            expect(subject.transfer_requests.count).to eq(1)
          end

          it 'sets the expected asset' do
            expect(transfer_request.asset).to eq(asset)
          end

          it 'sets the expected target_asset' do
            expect(transfer_request.target_asset).to eq(target_asset.receptacle)
          end

          it 'sets submission id on the transfer request' do
            expect(transfer_request.submission_id).to eq(outer_request.submission_id)
          end

          it 'sets request_id on the target aliquot' do
            expect(target_asset.aliquots.first.request_id).to eq(outer_request.id)
          end
        end
      end
    end

    context 'and two outer requests in the same submission' do
      let(:submission) { create :submission }
      let!(:outer_request) { create :request, asset:, submission: }
      let!(:other_outer_request) { create :request, asset:, submission: }

      describe '#save' do
        let(:transfer_request) { subject.transfer_requests.first }

        context 'specifying submission' do
          let(:creation_attributes) do
            {
              user:,
              transfer_requests_attributes: [
                { asset:, target_asset:, submission: outer_request.submission }
              ]
            }
          end

          it 'is invalid' do
            expect(subject).not_to be_valid
          end
        end

        context 'specifying outer_request' do
          let(:creation_attributes) do
            {
              user:,
              transfer_requests_attributes: [{ asset:, target_asset:, outer_request: }]
            }
          end

          before { expect(subject.save).to be true }

          it 'creates a transfer request' do
            expect(subject.transfer_requests.count).to eq(1)
          end

          it 'sets the expected asset' do
            expect(transfer_request.asset).to eq(asset)
          end

          it 'sets the expected target_asset' do
            expect(transfer_request.target_asset).to eq(target_asset.receptacle)
          end

          it 'sets submission id on the transfer request' do
            expect(transfer_request.submission_id).to eq(outer_request.submission_id)
          end

          it 'sets request_id on the target aliquot' do
            expect(target_asset.aliquots.first.request_id).to eq(outer_request.id)
          end
        end
      end
    end
  end
end
