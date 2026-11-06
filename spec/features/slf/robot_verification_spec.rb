# frozen_string_literal: true

require 'rails_helper'
require_relative 'cherrypicking_helpers'

RSpec.describe 'Robot verification', :js do
  include SlfCherrypickingHelpers

  it 'orders three source plates by bed and accepts scanner carriage returns' do
    released_cherrypicking_batch(sample_count: 2, barcodes: %w[SQPD-1 SQPD-10 SQPD-5], minimum_pick: '1.0')
    scan_verification
    verify_beds
    sources = %w[SQPD-1 SQPD-10 SQPD-5].flat_map { |barcode| [[barcode, 1], [barcode, 9]] }
    expect_robot_download(buffer_volumes: ['9.8'] * 6, sample_volumes: ['3.2'] * 6, sources: sources)
  end

  it 'honours the minimum robot sample picking volume' do
    released_cherrypicking_batch
    scan_verification
    verify_beds
    expect_robot_download(buffer_volumes: %w[8.0 8.0], sample_volumes: %w[5.0 5.0],
                          sources: [['SQPD-1234567', 1], ['SQPD-1234567', 9]])
  end

  it 'updates source volumes only once even when the same batch is verified twice' do
    released_cherrypicking_batch
    2.times do
      scan_verification
      verify_beds
      plate = source_plates.first
      expect(plate.wells.located_at('A1').first.reload.get_current_volume).to eq(5.0)
      expect(plate.wells.located_at('A2').first.reload.get_current_volume).to eq(6.0)
    end
  end

  it 'honours the minimum robot water picking volume for low-concentration samples' do
    released_cherrypicking_batch(low: true)
    scan_verification
    verify_beds
    expect_robot_download(buffer_volumes: %w[5.0 5.0], sample_volumes: %w[10.0 11.0],
                          sources: [['SQPD-1234567', 1], ['SQPD-1234567', 9]])
  end

  it 'does not submit carriage-return scanner input until the final barcode and downloads all 96 picks' do
    released_cherrypicking_batch(sample_count: 96, minimum_pick: '1.0')
    scan_verification(auto_submit: true)
    verify_beds(carriage_returns: false)
    # Literal expected volumes from the Cucumber document, not calculated with production logic.
    buffers = %w[
      9.8 10.0 10.2 10.3 10.4 10.0 10.1 10.3 9.8 10.0 10.2 10.3 10.4 10.0 10.1 10.3
      9.9 10.0 10.2 10.3 9.8 10.0 10.2 10.3 9.9 10.0 10.2 10.3 9.8 10.0 10.2 10.3
      9.9 10.1 10.2 10.3 9.9 10.0 10.2 10.3 9.9 10.1 10.2 10.4 9.9 10.0 10.2 10.3
      9.9 10.1 10.2 10.4 9.9 10.1 10.2 10.3 9.9 10.1 10.2 10.4 9.9 10.1 10.2 10.4
      9.9 10.1 10.3 10.4 9.9 10.1 10.2 10.4 10.0 10.1 10.3 10.4 9.9 10.1 10.2 10.4
      10.0 10.1 10.3 10.4 9.9 10.1 10.3 10.4 10.0 10.1 10.3 10.4 10.0 10.1 10.3 10.4
    ]
    volumes = %w[
      3.2 3.0 2.8 2.7 2.6 3.0 2.9 2.7 3.2 3.0 2.8 2.7 2.6 3.0 2.9 2.7
      3.1 3.0 2.8 2.7 3.2 3.0 2.8 2.7 3.1 3.0 2.8 2.7 3.2 3.0 2.8 2.7
      3.1 2.9 2.8 2.7 3.1 3.0 2.8 2.7 3.1 2.9 2.8 2.6 3.1 3.0 2.8 2.7
      3.1 2.9 2.8 2.6 3.1 2.9 2.8 2.7 3.1 2.9 2.8 2.6 3.1 2.9 2.8 2.6
      3.1 2.9 2.7 2.6 3.1 2.9 2.8 2.6 3.0 2.9 2.7 2.6 3.1 2.9 2.8 2.6
      3.0 2.9 2.7 2.6 3.1 2.9 2.7 2.6 3.0 2.9 2.7 2.6 3.0 2.9 2.7 2.6
    ]
    expect_robot_download(buffer_volumes: buffers, sample_volumes: volumes,
                          sources: (1..96).map { |position| ['SQPD-1234567', position] })
  end
end
