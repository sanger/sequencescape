# frozen_string_literal: true
RSpec.describe 'Receptacle::DownstreamAliquotsRemovalSpec::Mixin' do
  describe '#allow_to_remove_downstream_aliquots?' do
    # Labware
    let(:original_plate) { create(:plate_with_untagged_wells, well_count: 1) }
    let(:original_well) { original_plate.wells.first }
    let(:plates) { create_list(:plate, 3, well_count: 1) }
    let(:wells) { plates.map(&:wells).flatten }

    # Requests
    let!(:outer_requests_graph) do
      [
        create(:library_creation_request, asset: original_well, target_asset: wells[0]),
        create(:multiplexed_library_creation_request, asset: wells[0], target_asset: wells[1]),
        create(:sequencing_request, asset: wells[1], target_asset: wells[2])
      ]
    end

    before do
      # We build the submission
      create(:submission, requests: outer_requests_graph)

      # We modify the receptacles so the reference the right outer request in each step of the path
      original_well.aliquots.first&.update(request: outer_requests_graph[0])
      wells[0].aliquots.first&.update(request: outer_requests_graph[1])
      wells[1].aliquots.first&.update(request: outer_requests_graph[2])

      # We create an asset link between the multiplexing and the start of sequencing
      create(:asset_link, ancestor: wells[1].plate, descendant: wells[2].plate)
    end

    context 'when any of the downstream assets have a batch' do
      let(:batch) { create(:sequencing_batch, request_count: 1) }

      before { outer_requests_graph[2].update(batch: batch) }

      it 'returns false' do
        expect(original_well).not_to be_allow_to_remove_downstream_aliquots
      end
    end

    context 'when none of the downstream assets have a batch' do
      it 'returns true' do
        expect(original_well).to be_allow_to_remove_downstream_aliquots
      end
    end
  end
end
