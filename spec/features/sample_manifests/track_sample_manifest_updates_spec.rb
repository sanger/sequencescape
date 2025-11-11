# frozen_string_literal: true

require 'rails_helper'
require 'timecop'

describe 'track SampleManifest updates', :sample_manifest do
  include FetchTable

  def load_manifest_spec
    SampleManifestExcel.configure do |config|
      config.folder = File.join('spec', 'data', 'sample_manifest_excel')
      config.tag_group = create(:tag_group).name
      config.load!
    end
  end

  let(:user) { create(:user, login: 'john') }
  let(:new_user) { create(:user, login: 'jane') }
  let!(:printer) { create(:barcode_printer) }
  let!(:supplier) { create(:supplier) }
  let!(:study) { create(:study) }

  before do
    create(:insdc_country, name: 'United Kingdom')
    travel_to(Time.zone.local(2010, 7, 12, 10, 25, 0))
    login_user user
    load_manifest_spec
    visit(study_path(study))
    click_link('Sample Manifests')
  end

  it 'Some samples get updated by a manifest and events get created' do
    broadcast_events_count = BroadcastEvent.count
    expect(page).to have_content('Create manifest for plates')

    expect(PlateBarcode).to receive(:create_barcode).and_return(build(:plate_barcode, barcode: 'SQPD-1234567'))
    sample_manifest = create(:sample_manifest, study:, supplier:, user:)
    sample_manifest.generate

    expect(BroadcastEvent.count).to eq broadcast_events_count + 1

    Delayed::Worker.new.work_off

    samples =
      sample_manifest.sample_manifest_assets.each_with_index do |sample_manifest_asset, index|
        sample_manifest_asset.update(sanger_sample_id: "sample_#{index}")
      end

    visit('/sdb/')
    click_on 'View all manifests'
    attach_file('File to upload', 'test/data/test_blank_wells.csv')
    click_button 'Upload manifest'

    expect(BroadcastEvent.count).to eq broadcast_events_count + 2
    updated_broadcast_event = BroadcastEvent.last

    # subjects are 1 study, 1 plate and 11 samples
    expect(updated_broadcast_event.subjects.count).to eq 13

    sample_1 = Sample.find_by!(sanger_sample_id: 'sample_1')

    visit(history_sample_path(sample_1))
    table = [
      ['Message', 'Content', 'Created at', 'Created by'],
      ['Created by Sample Manifest', '2010-07-12', 'Monday 12 July, 2010', 'john'],
      ['Updated by Sample Manifest', '2010-07-12', 'Monday 12 July, 2010', 'john']
    ]

    expect(fetch_table('table#events')).to eq(table)

    # A different user logs in and updates the manifest
    login_user new_user
    visit('/sdb/')
    click_on 'View all manifests'
    attach_file('File to upload', 'test/data/test_blank_wells_with_no_blanks.csv')

    # upload without override
    click_button 'Upload manifest'

    expect(BroadcastEvent.count).to eq broadcast_events_count + 3
    updated_broadcast_event = BroadcastEvent.last

    # subjects are 1 study, 1 plate and 1 samples (only 'new' ones)
    expect(updated_broadcast_event.subjects.count).to eq 3

    visit(history_sample_path(sample_1))
    table = [
      ['Message', 'Content', 'Created at', 'Created by'],
      ['Created by Sample Manifest', '2010-07-12', 'Monday 12 July, 2010', 'john'],
      ['Updated by Sample Manifest', '2010-07-12', 'Monday 12 July, 2010', 'john']
    ]
    expect(fetch_table('table#events')).to eq(table)

    sample_7 = Sample.find_by!(sanger_sample_id: 'sample_7')

    visit(history_sample_path(sample_7))
    table = [
      ['Message', 'Content', 'Created at', 'Created by'],
      ['Created by Sample Manifest', '2010-07-12', 'Monday 12 July, 2010', 'john'],
      ['Updated by Sample Manifest', '2010-07-12', 'Monday 12 July, 2010', 'jane']
    ]
    expect(fetch_table('table#events')).to eq(table)

    visit('/sdb/')
    click_on 'View all manifests'
    attach_file('File to upload', 'test/data/test_blank_wells_with_no_blanks_new_data.csv')

    # upload with override
    check 'Override previously uploaded samples'
    click_button 'Upload manifest'
    Delayed::Worker.new.work_off

    expect(BroadcastEvent.count).to eq broadcast_events_count + 4
    updated_broadcast_event = BroadcastEvent.last
    expect(updated_broadcast_event.subjects.count).to eq 14

    visit(history_sample_path(sample_1))
    table = [
      ['Message', 'Content', 'Created at', 'Created by'],
      ['Created by Sample Manifest', '2010-07-12', 'Monday 12 July, 2010', 'john'],
      ['Updated by Sample Manifest', '2010-07-12', 'Monday 12 July, 2010', 'john'],
      ['Updated by Sample Manifest', '2010-07-12', 'Monday 12 July, 2010', 'jane']
    ]
    expect(fetch_table('table#events')).to eq(table)

    visit(history_sample_path(sample_7))

    table = [
      ['Message', 'Content', 'Created at', 'Created by'],
      ['Created by Sample Manifest', '2010-07-12', 'Monday 12 July, 2010', 'john'],
      ['Updated by Sample Manifest', '2010-07-12', 'Monday 12 July, 2010', 'jane'],
      ['Updated by Sample Manifest', '2010-07-12', 'Monday 12 July, 2010', 'jane']
    ]

    expect(fetch_table('table#events')).to eq(table)
    asset = Labware.find_by_barcode('SQPD-1234567')
    visit(history_labware_path(asset))
    table = [
      ['Message', 'Content', 'Created at', 'Created by'],
      ['Created by Sample Manifest', '2010-07-12', 'Monday 12 July, 2010', 'john'],
      ['Updated by Sample Manifest', '2010-07-12', 'Monday 12 July, 2010', 'john'],
      ['Updated by Sample Manifest', '2010-07-12', 'Monday 12 July, 2010', 'jane'],
      ['Updated by Sample Manifest', '2010-07-12', 'Monday 12 July, 2010', 'jane']
    ]
    expect(fetch_table('table#events')).to eq(table)
  end
end
