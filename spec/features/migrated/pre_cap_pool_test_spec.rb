# frozen_string_literal: true

require 'rails_helper'

RSpec.feature 'Pre-capture pools should be defined at submission',
              :api, :barcode_service, :json, :mutiple_orders, :new_api,
              :single_sign_on, :submission do
  let(:user) { create(:user) }
  let(:study) { create(:study) }
  let(:project) { create(:project) }

  # Create a pre-capture pooling submission setup similar to the retired
  # submission template 'Illumina-A - HTP ISC - Single ended sequencing'.
  let(:isc_request_type) do
    create(:request_type,
           name: 'ISC Request',
           key: 'isc_request',
           asset_type: 'Well',
           request_class: Pulldown::Requests::IscLibraryRequest)
  end
  let(:multiplexing_request_type) do
    create(:request_type,
           name: 'Multiplexing Request',
           key: 'multiplexing_request',
           request_class: Request::Multiplexing,
           for_multiplexing: true)
  end
  let(:sequencing_request_type) do
    create(:request_type,
           name: 'Sequencing Request',
           key: 'sequencing_request',
           request_class: SequencingRequest)
  end

  let(:submission_template) do
    create(:submission_template,
           name: 'Pre-capture pools submission template',
           submission_class_name: 'LinearSubmission',
           request_types: [
             isc_request_type,
             multiplexing_request_type,
             sequencing_request_type
           ],
           study: study,
           project: project)
  end

  let(:plate_purpose) { create(:input_plate_purpose, name: 'Cherrypicked') }
  let(:plate) { create(:plate_with_untagged_wells, plate_purpose: plate_purpose, sample_count: 96) }

  let(:bait_library) { create(:bait_library, name: 'Human all exon 50MB') }

  let(:order1) do
    order_attributes = {
      study: study,
      project: project,
      user: user,
      assets: plate.wells.located_at(%w[A1 B1]),
      request_options: {
        library_type: 'Agilent Pulldown',
        fragment_size_required_from: 100,
        fragment_size_required_to: 200,
        pre_capture_plex_level: 1,
        bait_library_name: bait_library.name,
        read_length: 54
      }
    }
    submission_template.create_order!(order_attributes)
  end

  let(:order2) do
    order_attributes = {
      study: study,
      project: project,
      user: user,
      assets: plate.wells.located_at(%w[C1 D1 E1]),
      pre_cap_group: 1,
      request_options: {
        library_type: 'Agilent Pulldown',
        fragment_size_required_from: 100,
        fragment_size_required_to: 200,
        pre_capture_plex_level: 2,
        bait_library_name: bait_library.name,
        read_length: 54
      }
    }
    submission_template.create_order!(order_attributes)
  end

  let(:order3) do
    order_attributes = {
      study: study,
      project: project,
      user: user,
      assets: plate.wells.located_at(%w[F1 G1]),
      pre_cap_group: 1,
      request_options: {
        library_type: 'Agilent Pulldown',
        fragment_size_required_from: 100,
        fragment_size_required_to: 200,
        pre_capture_plex_level: 2,
        bait_library_name: bait_library.name,
        read_length: 54
      }
    }
    submission_template.create_order!(order_attributes)
  end

  let(:order4) do
    order_attributes = {
      study: study,
      project: project,
      user: user,
      assets: plate.wells.located_at(%w[H1 A2 B2]),
      request_options: {
        library_type: 'Agilent Pulldown',
        fragment_size_required_from: 100,
        fragment_size_required_to: 200,
        pre_capture_plex_level: 2,
        bait_library_name: bait_library.name,
        read_length: 54
      }
    }
    submission_template.create_order!(order_attributes)
  end

  scenario 'Creating a submission with multiple orders' do
    path = '/api/v2/submissions'
    body = {
      data: {
        type: 'submissions',
        attributes: {
          and_submit: true # skip separate submission step
        },
        relationships: {
          orders: {
            data: [
              { type: 'orders', id: order1.id },
              { type: 'orders', id: order2.id },
              { type: 'orders', id: order3.id },
              { type: 'orders', id: order4.id }
            ]
          },
          user: {
            data: { type: 'users', id: user.id }
          }
        }
      }
    }.to_json
    headers = {
      'CONTENT_TYPE' => 'application/vnd.api+json',
      'HTTP_ACCEPT' => 'application/vnd.api+json'
    }

    page.driver.post path, body, headers

    expect(page.status_code).to eq(201) # Created

    response = JSON.parse(page.driver.response.body)

    # The submission state should be 'pending' because we used the 'and_submit'
    # attribute to skip the separate submission step. Without the attribute,
    # the state would be 'building' and we would need a separate POST to
    # /api/v2/submissions/{id}/submit .
    expect(response.dig('data', 'attributes', 'state')).to eq('pending')

    count = Delayed::Job.count
    expect(count).to eq(1), "There should be 1 delayed job, but found #{count}"

    Delayed::Worker.new(quiet: ENV['LOUD_DELAYED_JOBS'].nil?).work_off(count)
    errors = Delayed::Job.all.map { |j| j.run_at? && j.last_error }.compact_blank
    expect(errors).to be_empty, "Delayed jobs have failed: #{errors.to_yaml}"
    expect(Delayed::Job.count).to eq(0), "There are #{Delayed::Job.count} jobs left to process"

    expect(PreCapturePool.count).to eq(7)

    expected_pools = ['A1'], ['B1'], %w[C1 D1], %w[E1 F1], ['G1'], %w[A2 H1], ['B2']
    pools = plate.pre_cap_groups.values.map { |g| g[:wells].sort }

    expect(pools).to eq(expected_pools)
  end
end
