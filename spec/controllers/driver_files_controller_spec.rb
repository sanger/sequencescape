# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DriverFilesController do
  let(:current_user) { create(:user) }

  describe '#show' do
    let(:robot) { create(:full_robot, generation_behaviour_value: 'Tecan') }

    let(:time) { Time.zone.local(2010, 7, 12, 10, 25, 0) }
    let(:source_plate) { create(:plate, well_count: 1) }
    let(:destination_plate) { create(:plate, well_count: 1, well_factory: :picked_well) }
    let(:pipeline) { create(:cherrypick_pipeline) }

    let(:transfers) { { source_plate.wells[0] => destination_plate.wells.first } }

    let(:requests) do
      create_list(
        :cherrypick_request,
        1,
        asset: source_plate.wells.first,
        target_asset: destination_plate.wells.first,
        request_type: pipeline.request_types.first,
        state: 'passed'
      )
    end

    let(:batch) { create(:batch, requests: requests, pipeline: pipeline, user: current_user) }
    let(:generator_id) { robot.generation_behaviour_properties.first.id }

    before do
      get :show, params: { batch_id: batch.id, robot_id: robot.id, pick_number: 1, generator_id: generator_id },
                 session: { user: current_user.id }
    end

    it 'returns an appropriate file' do
      expect(response.media_type).to eq 'text/plain'
      expect(response.headers['Content-Disposition']).to(
        include("attachment; filename=\"#{batch.id}_batch_#{destination_plate.human_barcode}_1.gwl\"")
      )
    end
  end
end
