# frozen_string_literal: true

require 'rails_helper'
require 'timecop'

feature 'track SampleManifest updates' do
  include FetchTable

  def load_manifest_spec
    SampleManifestExcel.configure do |config|
      config.folder = File.join('spec', 'data', 'sample_manifest_excel')
      config.load!
    end
  end

  let(:user) { create :user, login: 'john' }
  let(:new_user) { create :user, login: 'jane' }
  let!(:printer) { create :barcode_printer }
  let(:barcode) { 1234567 }
  let!(:supplier) { create :supplier }
  let!(:study) { create :study }

  background do
    new_time = Time.zone.local(2010, 7, 12, 10, 25, 0)
    Timecop.freeze new_time
    login_user user
    load_manifest_spec
    visit(study_path(study))
    click_link('Sample Manifests')
  end

  scenario 'Some samples get updated by a manifest and events get created' do
    broadcast_events_count = BroadcastEvent.count
    expect(page).to have_content('Create manifest for plates')

    expect(PlateBarcode).to receive(:create).and_return(build(:plate_barcode, barcode: barcode))
    sample_manifest = create :sample_manifest, study: study, supplier: supplier, user: user
    sample_manifest.generate

    expect(BroadcastEvent.count).to eq broadcast_events_count + 1

    samples = sample_manifest.samples.each_with_index do |sample, index|
      sample.update(sanger_sample_id: "sample_#{index}")
    end
    sample1 = samples[1]
    sample7 = samples[7]

    visit(history_sample_path(sample1))
    table = [['Message', 'Content', 'Created at', 'Created by'],
             ['Created by Sample Manifest', '2010-07-12', 'Monday 12 July, 2010', 'john']]
    expect(fetch_table('table#events')).to eq(table)

    visit(history_sample_path(sample7))
    table = [['Message', 'Content', 'Created at', 'Created by'],
             ['Created by Sample Manifest', '2010-07-12', 'Monday 12 July, 2010', 'john']]
    expect(fetch_table('table#events')).to eq(table)

    visit('/sdb/')
    click_on 'View all manifests'
    attach_file('File to upload', 'test/data/test_blank_wells.csv')
    click_button 'Upload manifest'
    Delayed::Worker.new.work_off

    expect(BroadcastEvent.count).to eq broadcast_events_count + 2
    updated_broadcast_event = BroadcastEvent.last
    # subjects are 1 study, 1 plate and 7 samples
    expect(updated_broadcast_event.subjects.count).to eq 9

    visit(history_sample_path(sample1))
    table = [['Message', 'Content', 'Created at', 'Created by'],
             ['Created by Sample Manifest', '2010-07-12', 'Monday 12 July, 2010', 'john'],
             ['Updated by Sample Manifest', '2010-07-12', 'Monday 12 July, 2010', 'john']]
    expect(fetch_table('table#events')).to eq(table)

    visit(history_sample_path(sample7))
    table = [['Message', 'Content', 'Created at', 'Created by'],
             ['Created by Sample Manifest', '2010-07-12', 'Monday 12 July, 2010', 'john']]
    expect(fetch_table('table#events')).to eq(table)

    # A different user logs in and updates the manifest
    login_user new_user
    visit('/sdb/')
    click_on 'View all manifests'
    attach_file('File to upload', 'test/data/test_blank_wells_with_no_blanks.csv')

    # upload without override
    click_button 'Upload manifest'
    Delayed::Worker.new.work_off

    expect(BroadcastEvent.count).to eq broadcast_events_count + 3
    updated_broadcast_event = BroadcastEvent.last
    # subjects are 1 study, 1 plate and 5 samples (only 'new' ones)
    expect(updated_broadcast_event.subjects.count).to eq 7

    visit(history_sample_path(sample1))
    table = [['Message', 'Content', 'Created at', 'Created by'],
             ['Created by Sample Manifest', '2010-07-12', 'Monday 12 July, 2010', 'john'],
             ['Updated by Sample Manifest', '2010-07-12', 'Monday 12 July, 2010', 'john']]
    expect(fetch_table('table#events')).to eq(table)

    visit(history_sample_path(sample7))
    table = [['Message', 'Content', 'Created at', 'Created by'],
             ['Created by Sample Manifest', '2010-07-12', 'Monday 12 July, 2010', 'john'],
             ['Updated by Sample Manifest', '2010-07-12', 'Monday 12 July, 2010', 'jane']]
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

    visit(history_sample_path(sample1))
    table = [['Message', 'Content', 'Created at', 'Created by'],
             ['Created by Sample Manifest', '2010-07-12', 'Monday 12 July, 2010', 'john'],
             ['Updated by Sample Manifest', '2010-07-12', 'Monday 12 July, 2010', 'john'],
             ['Updated by Sample Manifest', '2010-07-12', 'Monday 12 July, 2010', 'jane']]
    expect(fetch_table('table#events')).to eq(table)

    visit(history_sample_path(sample7))

    table = [['Message', 'Content', 'Created at', 'Created by'],
             ['Created by Sample Manifest', '2010-07-12', 'Monday 12 July, 2010', 'john'],
             ['Updated by Sample Manifest', '2010-07-12', 'Monday 12 July, 2010', 'jane'],
             ['Updated by Sample Manifest', '2010-07-12', 'Monday 12 July, 2010', 'jane']]

    expect(fetch_table('table#events')).to eq(table)
    asset = Asset.find_from_barcode('1221234567841')
    visit(history_asset_path(asset))
    table = [['Message', 'Content', 'Created at', 'Created by'],
             ['Created by Sample Manifest', '2010-07-12', 'Monday 12 July, 2010', 'john'],
             ['Updated by Sample Manifest', '2010-07-12', 'Monday 12 July, 2010', 'john'],
             ['Updated by Sample Manifest', '2010-07-12', 'Monday 12 July, 2010', 'jane'],
             ['Updated by Sample Manifest', '2010-07-12', 'Monday 12 July, 2010', 'jane']]
    expect(fetch_table('table#events')).to eq(table)
  end

  after do
    Timecop.return
  end
end
