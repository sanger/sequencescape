# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RobotVerificationsController do
  let(:user) { create :user, barcode: 'ID41440E', swipecard_code: '1234567' }
  let(:batch) { create :batch, barcode: '6262' }
  let(:robot) do
    create :robot_with_verification_behaviour, barcode: '1', number_of_sources: 4, number_of_destinations: 1
  end
  let(:plate) { create :plate, barcode: 'SQPD-142334' }

  before { session[:user] = user.id }

  describe '#index' do
    before { get :index, session: { user: user.id } }

    it 'is successful' do
      expect(response).to have_http_status(:success)
      expect(response).to render_template('index')
    end
  end

  describe '#download' do
    let(:expected_layout) do
      [{ 'SQPD-142334' => 1 }, { 'SQPD-127168' => 3, 'SQPD-134443' => 4, 'SQPD-127162' => 1, 'SQPD-127167' => 2 }]
    end
    let!(:before_event_count) { Event.count }
    let(:plate_types) do
      {
        'SQPD-127162' => 'ABgene_0765',
        'SQPD-127167' => 'ABgene_0765',
        'SQPD-127168' => 'ABgene_0765',
        'SQPD-134443' => 'ABgene_0765'
      }
    end
    let(:barcodes) { { destination_plate_barcode: plate.machine_barcode } }
    let(:bed_barcodes) do
      { '1' => '580000001806', '2' => '580000002810', '3' => '580000003824', '4' => '580000004838' }
    end
    let(:plate_barcodes) do
      {
        'SQPD-127162' => 'SQDP-127162',
        'SQPD-127167' => 'SQDP-127167',
        'SQPD-127168' => 'SQPD-127168',
        'SQPD-134443' => 'DN134443T'
      }
    end
    let(:destination_bed_barcodes) { { '1' => '580000005842' } }
    let(:destination_plate_barcodes) { { plate.machine_barcode => plate.machine_barcode } }
    let(:download_params) do
      {
        user_id: user.id,
        batch_id: batch.id,
        robot_id: robot.id,
        plate_types:,
        barcodes:,
        bed_barcodes:,
        plate_barcodes:,
        destination_bed_barcodes:,
        destination_plate_barcodes:,
        pick_number: 1
      }
    end

    before do
      expected_layout[1].each_with_index do |(barcode, _sort_number), index|
        source_plate = create(:plate, barcode:)
        position = Map.for_position_on_plate(index + 1, 96, source_plate.asset_shape).first
        well = create :well, map: position, plate: source_plate
        target_well = create(:well, map: position, plate:)
        well_request = create :request, state: 'passed', asset: well, target_asset: target_well
        batch.requests << well_request
      end
      robot.save
    end

    context 'with valid inputs' do
      before { post :download, params: download_params }

      it 'is successful' do
        expect(response).to have_http_status(:success)
        expect(Event.count).to eq(before_event_count + 1)
      end
    end

    context 'with invalid inputs' do
      context 'when nothing is scanned' do
        let(:bed_barcodes) { { '1' => '', '2' => '', '3' => '', '4' => '' } }
        let(:plate_barcodes) { { 'SQPD-127162' => '', 'SQPD-127167' => '', 'SQPD-127168' => '', 'SQPD-134443' => '' } }
        let(:destination_bed_barcodes) { { '1' => '' } }
        let(:destination_plate_barcodes) { { plate.machine_barcode => '' } }

        before { post :download, params: download_params }

        it 'redirects and sets the flash error' do
          expect(response).to redirect_to(robot_verifications_path)
          expect(flash[:error]).to include('Error')
          expect(Event.count).to eq(before_event_count + 1)
        end
      end

      context 'when the source plates are missing' do
        let(:plate_barcodes) { { 'SQPD-127162' => '', 'SQPD-127167' => '', 'SQPD-127168' => '', 'SQPD-134443' => '' } }

        before { post :download, params: download_params }

        it 'redirects and displays an error', :aggregate_failures do
          expect(response).to redirect_to(robot_verifications_path)
          expect(flash[:error]).to include('Error')
          expect(Event.count).to eq(before_event_count + 1)
        end
      end

      context 'when the source beds are missing' do
        let(:bed_barcodes) { { '1' => '', '2' => '', '3' => '', '4' => '' } }

        before { post :download, params: download_params }

        it 'redirects and displays an error', :aggregate_failures do
          expect(response).to redirect_to(robot_verifications_path)
          expect(flash[:error]).to include('Error')
          expect(Event.count).to eq(before_event_count + 1)
        end
      end

      context 'when the source plates are mixed up' do
        let(:plate_barcodes) do
          {
            'SQPD-127167' => 'SQPD-127162',
            'SQPD-127162' => 'SQPD-127167',
            'SQPD-134443' => 'SQPD-127168',
            'SQPD-127168' => 'SQPD-134443'
          }
        end

        before { post :download, params: download_params }

        it 'redirects and displays an error', :aggregate_failures do
          expect(response).to redirect_to(robot_verifications_path)
          expect(flash[:error]).to include('Error')
          expect(Event.count).to eq(before_event_count + 1)
        end
      end

      context 'when the source beds are mixed up' do
        let(:bed_barcodes) do
          { '4' => '580000001806', '3' => '580000002810', '1' => '580000003824', '2' => '580000004838' }
        end

        before { post :download, params: download_params }

        it 'redirects and displays an error', :aggregate_failures do
          expect(response).to redirect_to(robot_verifications_path)
          expect(flash[:error]).to include('Error')
          expect(Event.count).to eq(before_event_count + 1)
        end
      end

      context 'when 2 source beds and plates are mixed up' do
        let(:bed_barcodes) do
          { '1' => 'SQPD-127162', '2' => '580000002810', '3' => '580000003824', '4' => '580000004838' }
        end
        let(:plate_barcodes) do
          {
            'SQPD-127162' => '580000001806',
            'SQPD-127167' => 'SQPD-127167',
            'SQPD-127168' => 'SQPD-127168',
            'SQPD-134443' => 'SQPD-134443'
          }
        end

        before { post :download, params: download_params }

        it 'redirects and displays an error', :aggregate_failures do
          expect(response).to redirect_to(robot_verifications_path)
          expect(flash[:error]).to include('Error')
          expect(Event.count).to eq(before_event_count + 1)
        end
      end

      context 'when the destination plate is missing' do
        let(:destination_plate_barcodes) { { plate.machine_barcode => '' } }

        before { post :download, params: download_params }

        it 'redirects and displays an error', :aggregate_failures do
          expect(response).to redirect_to(robot_verifications_path)
          expect(flash[:error]).to include('Error')
          expect(Event.count).to eq(before_event_count + 1)
        end
      end

      context 'when the destination bed is missing' do
        let(:destination_bed_barcodes) { { '1' => '' } }

        before { post :download, params: download_params }

        it 'redirects and displays an error', :aggregate_failures do
          expect(response).to redirect_to(robot_verifications_path)
          expect(flash[:error]).to include('Error')
          expect(Event.count).to eq(before_event_count + 1)
        end
      end

      context 'when the source and destination plates are mixed up' do
        let(:destination_bed_barcodes) { { '1' => plate.machine_barcode } }
        let(:destination_plate_barcodes) { { plate.machine_barcode => '580000005842' } }

        before { post :download, params: download_params }

        it 'redirects and displays an error', :aggregate_failures do
          expect(response).to redirect_to(robot_verifications_path)
          expect(flash[:error]).to include('Error')
          expect(Event.count).to eq(before_event_count + 1)
        end
      end

      context 'when there are spaces in the input barcodes' do
        let(:bed_barcodes) do
          { '1' => ' 580000001806', '2' => '580000002810    ', '3' => '  580000003824', '4' => '580000004838' }
        end
        let(:plate_barcodes) do
          {
            'SQPD-127162' => 'SQPD-127162     ',
            'SQPD-127167' => 'SQPD-127167 ',
            'SQPD-127168' => 'SQPD-127168',
            'SQPD-134443' => 'SQPD-134443'
          }
        end

        before { post :download, params: download_params }

        it 'is successful', :aggregate_failures do
          expect(response).to have_http_status(:success)
          expect(Event.count).to eq(before_event_count + 1)
        end
      end
    end

    describe '#submission' do
      let(:well) { create :well, plate: }
      let(:well_request) { create :request, state: 'passed' }
      let(:source_plate) { create :plate, barcode: 'SQPD-1234' }
      let(:target_well) { create :well, plate: source_plate }

      before do
        well_request.asset = well
        well_request.target_asset = target_well
        well_request.save
        batch.requests << well_request
      end

      context 'with valid inputs' do
        let(:submission_params) do
          {
            barcodes: {
              batch_barcode: '550006262686',
              robot_barcode: '4880000001780',
              destination_plate_barcode: plate.machine_barcode,
              user_barcode: '1234567'
            }
          }
        end

        before { post :submission, params: submission_params }

        it('is successful') { is_expected.to respond_with :success }
      end

      context 'with invalid batch' do
        let(:submission_params) do
          {
            barcodes: {
              batch_barcode: '1111111111111',
              robot_barcode: '4880000001780',
              destination_plate_barcode: plate.machine_barcode,
              user_barcode: '2470041440697'
            }
          }
        end

        before { post :submission, params: submission_params }

        it 'works', :aggregate_failures do # rubocop:todo RSpec/ExampleWording
          expect(response).to redirect_to(robot_verifications_path)
          expect(flash[:error]).to include('Worksheet barcode invalid')
        end
      end

      context 'with invalid robot' do
        let(:submission_params) do
          {
            barcodes: {
              batch_barcode: '550006262686',
              robot_barcode: '111111111111',
              destination_plate_barcode: plate.machine_barcode,
              user_barcode: '2470041440697'
            }
          }
        end

        before { post :submission, params: submission_params }

        it 'works', :aggregate_failures do # rubocop:todo RSpec/ExampleWording
          expect(response).to redirect_to(robot_verifications_path)
          expect(flash[:error]).to include('Could not find robot 111111111111')
        end
      end

      context 'with invalid destination plate' do
        let(:submission_params) do
          {
            barcodes: {
              batch_barcode: '550006262686',
              robot_barcode: '4880000001780',
              destination_plate_barcode: '111111111111',
              user_barcode: '2470041440697'
            }
          }
        end

        before { post :submission, params: submission_params }

        it 'works', :aggregate_failures do # rubocop:todo RSpec/ExampleWording
          expect(response).to redirect_to(robot_verifications_path)
          expect(flash[:error]).to include('Destination plate barcode invalid')
        end
      end

      context 'with invalid user' do
        let(:submission_params) do
          {
            barcodes: {
              batch_barcode: '550006262686',
              robot_barcode: '4880000001780',
              destination_plate_barcode: plate.machine_barcode,
              user_barcode: '1111111111111'
            }
          }
        end

        before { post :submission, params: submission_params }

        it 'works', :aggregate_failures do # rubocop:todo RSpec/ExampleWording
          expect(response).to redirect_to(robot_verifications_path)
          expect(flash[:error]).to include('User barcode invalid')
        end
      end
    end
  end
end
