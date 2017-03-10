require 'rails_helper'
require 'shared_contexts/limber_shared_context'

describe WorkCompletion do
  include_context 'a limber target plate with submissions'

  describe '::create' do
    context 'without failed wells' do
      before(:each) do
        # We'll keep things simple for the moment.
        # Note: We explicitly pass in submission. Not only will this allow partial passing of plates,
        # but will also reduce coupling with transfer requests, and help push business logic out into
        # the client applications.
        WorkCompletion.create!(
          user: create(:user),
          target: target_plate,
          submissions: [target_submission]
        )
      end

      it 'has built correctly' do
        # If the submission isn't correctly built, we'll get misleading passes/failures
        expect(library_requests.count).to eq(tested_wells)
      end

      it 'passes the library requests' do
        expect(library_requests).to all(be_passed)
      end

      it 'does not pass the multiplex requests' do
        expect(multiplex_requests).to all(be_pending)
      end

      it 'does not pass the decoy submission' do
        expect(decoy_submission_requests).to all(be_started)
      end

      it 'joins up the library requests' do
        library_requests.each do |request|
          expect(request.target_asset).not_to be_nil
          expect(request.target_asset.plate).to eq(target_plate)
          expect(request.target_asset.map_description).to eq(request.asset.map_description)
        end
      end

      it 'joins up the multiplex requests' do
        expect(multiplex_requests.map(&:asset).uniq.size).to eq(tested_wells)
      end
    end

    context 'when wells are failed' do
      before(:each) do
        library_requests.first.fail!
        WorkCompletion.create!(
          user: create(:user),
          target: target_plate,
          submissions: [target_submission]
        )
      end

      it "doesn't pass the failed request" do
        expect(library_requests.first).to be_failed
      end
    end
  end
end
