# frozen_string_literal: true

require 'rails_helper'
require 'timecop'

describe 'Track SampleManifest updates', :js, :sample_manifest do
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
  end

  it 'Some samples get updated by a manifest and events get created' do
    visit(study_path(study))
    expect(page).to have_title('Sequencescape | Information (Study 1)')

    click_link('Sample Manifests')
    expect(page).to have_title('Sequencescape | Studies (Sample Manifests)')

    broadcast_events_count = BroadcastEvent.count
    expect(page).to have_text('Create manifest for plates')

    expect(PlateBarcode).to receive(:create_barcode).and_return(build(:plate_barcode, barcode: 'SQPD-1234567'))
    sample_manifest = create(:sample_manifest, study:, supplier:, user:)
    sample_manifest.generate

    expect(BroadcastEvent.count).to eq broadcast_events_count + 1

    Delayed::Worker.new.work_off

    sample_manifest.sample_manifest_assets.each_with_index do |sample_manifest_asset, index|
      sample_manifest_asset.update(sanger_sample_id: "sample_#{index}")
    end

    visit('/sdb/')
    expect(page).to have_title('Sequencescape | Home (Index)')

    click_on 'View all manifests'
    expect(page).to have_title('Sequencescape | Sample Manifests (Index)')

    attach_file('File to upload', 'test/data/test_blank_wells.csv')

    click_button 'Upload manifest'
    expect(page).to have_text('Sample manifest successfully uploaded.')

    expect(BroadcastEvent.count).to eq broadcast_events_count + 2
    updated_broadcast_event = BroadcastEvent.last

    # subjects are 1 study, 1 plate and 11 samples
    expect(updated_broadcast_event.subjects.count).to eq 13

    sample_1 = Sample.find_by!(sanger_sample_id: 'sample_1')
    sample_1_events = [
      ['Message', 'Content', 'Created at', 'Created by'],
      ['Created by Sample Manifest', sample_manifest.name, 'Monday 12 July, 2010 10:25', 'john'],
      ['Updated sample metadata',
       'Gender: not specified → Male ' \
       'Country of origin: not specified → United Kingdom ' \
       'Dna source: not specified → Genomic ' \
       'Volume: not specified → 10 ' \
       'Sample public name: not specified → Human ' \
       'Sample common name: not specified → Human ' \
       'Sample taxon: not specified → 9606 ' \
       'Sample description: not specified → Human ' \
       'Date of sample collection: not specified → 2022-12-12 ' \
       'Concentration: not specified → 20 ' \
       'Supplier name: not specified → aaaa ' \
       'Donor: not specified → 12345',
       'Monday 12 July, 2010 10:25', ''],
      ['Updated by Sample Manifest', sample_manifest.name, 'Monday 12 July, 2010 10:25', 'john']
    ]
    visit(history_sample_path(sample_1))
    expect(fetch_table('table#events')).to eq(sample_1_events)

    # A different user logs in and updates the manifest
    login_user new_user

    visit('/sdb/')
    expect(page).to have_title('Sequencescape | Home (Index)')

    click_on 'View all manifests'
    expect(page).to have_title('Sequencescape | Sample Manifests (Index)')

    attach_file('File to upload', 'test/data/test_blank_wells_with_no_blanks.csv')

    # upload without override
    click_button 'Upload manifest'
    expect(page).to have_text('Sample manifest successfully uploaded.')

    expect(BroadcastEvent.count).to eq broadcast_events_count + 3
    updated_broadcast_event = BroadcastEvent.last

    # subjects are 1 study, 1 plate and 1 samples (only 'new' ones)
    expect(updated_broadcast_event.subjects.count).to eq 3

    visit(history_sample_path(sample_1))
    # no changes made to sample_1 events
    expect(fetch_table('table#events')).to eq(sample_1_events)

    sample_7 = Sample.find_by!(sanger_sample_id: 'sample_7')
    sample_7_events = [
      ['Message', 'Content', 'Created at', 'Created by'],
      ['Created by Sample Manifest', sample_manifest.name, 'Monday 12 July, 2010 10:25', 'john'],
      ['Updated sample metadata',
       'Gender: not specified → Male ' \
       'Country of origin: not specified → United Kingdom ' \
       'Dna source: not specified → Genomic ' \
       'Volume: not specified → 10 ' \
       'Sample public name: not specified → Human ' \
       'Sample common name: not specified → Human ' \
       'Sample taxon: not specified → 10012 ' \
       'Sample description: not specified → Human ' \
       'Date of sample collection: not specified → 2022-12-07 ' \
       'Concentration: not specified → 20 ' \
       'Supplier name: not specified → xxxx',
       'Monday 12 July, 2010 10:25', ''],
      ['Updated by Sample Manifest', sample_manifest.name, 'Monday 12 July, 2010 10:25', 'jane']
    ]
    visit(history_sample_path(sample_7))
    expect(fetch_table('table#events')).to eq(sample_7_events)

    visit('/sdb/')
    expect(page).to have_title('Sequencescape | Home (Index)')

    click_on 'View all manifests'
    expect(page).to have_title('Sequencescape | Sample Manifests (Index)')

    attach_file('File to upload', 'test/data/test_blank_wells_with_no_blanks_new_data.csv')

    # upload with override
    check 'Override previously uploaded samples'
    check 'Overwrite volume'
    check 'Overwrite concentration'
    click_button 'Upload manifest'
    Delayed::Worker.new.work_off
    expect(page).to have_text('Sample manifest successfully uploaded.')

    expect(BroadcastEvent.count).to eq broadcast_events_count + 4
    updated_broadcast_event = BroadcastEvent.last
    expect(updated_broadcast_event.subjects.count).to eq 14

    visit(history_sample_path(sample_1))
    sample_1_events << [
      'Updated sample metadata',
      'Volume: 10 → 15 ' \
      'Date of sample collection: 2022-12-12 → 2022-12-01 ' \
      'Supplier name: aaaa → aaaa_updated',
      'Monday 12 July, 2010 10:25', ''
    ]
    sample_1_events << ['Updated by Sample Manifest', sample_manifest.name, 'Monday 12 July, 2010 10:25', 'jane']
    expect(fetch_table('table#events')).to eq(sample_1_events)

    visit(history_sample_path(sample_7))
    sample_7_events << ['Updated sample metadata', 'Volume: 10 → 15', 'Monday 12 July, 2010 10:25', '']
    sample_7_events << ['Updated by Sample Manifest', sample_manifest.name, 'Monday 12 July, 2010 10:25', 'jane']
    expect(fetch_table('table#events')).to eq(sample_7_events)

    asset = Labware.find_by_barcode('SQPD-1234567')
    visit(history_labware_path(asset))

    table = [
      ['Message', 'Content', 'Created at', 'Created by'],
      ['Created by Sample Manifest', sample_manifest.name, 'Monday 12 July, 2010 10:25', 'john'],
      ['Updated by Sample Manifest', sample_manifest.name, 'Monday 12 July, 2010 10:25', 'john'],
      ['Updated by Sample Manifest', sample_manifest.name, 'Monday 12 July, 2010 10:25', 'jane'],
      ['Updated by Sample Manifest', sample_manifest.name, 'Monday 12 July, 2010 10:25', 'jane']
    ]
    expect(fetch_table('table#events')).to eq(table)
  end

  describe 'Only update certain fields when override is selected' do
    it 'updates volume only when overwrite volume is selected' do
      visit(study_path(study))
      expect(page).to have_title('Sequencescape | Information (Study 1)')

      click_link('Sample Manifests')
      expect(page).to have_title('Sequencescape | Studies (Sample Manifests)')

      expect(page).to have_text('Create manifest for plates')

      expect(PlateBarcode).to receive(:create_barcode).and_return(build(:plate_barcode, barcode: 'SQPD-1234567'))
      sample_manifest = create(:sample_manifest, study:, supplier:, user:)
      sample_manifest.generate

      Delayed::Worker.new.work_off

      sample_manifest.sample_manifest_assets.each_with_index do |sample_manifest_asset, index|
        sample_manifest_asset.update(sanger_sample_id: "sample_#{index}")
      end

      visit('/sdb/')
      expect(page).to have_title('Sequencescape | Home (Index)')

      click_on 'View all manifests'
      expect(page).to have_title('Sequencescape | Sample Manifests (Index)')

      attach_file('File to upload', 'test/data/test_blank_wells.csv')

      click_button 'Upload manifest'
      expect(page).to have_text('Sample manifest successfully uploaded.')

      sample_8 = Sample.find_by!(sanger_sample_id: 'sample_8')
      sample_8_events = [
        ['Message', 'Content', 'Created at', 'Created by'],
        ['Created by Sample Manifest', sample_manifest.name, 'Monday 12 July, 2010 10:25', 'john'],
        ['Updated sample metadata',
         'Gender: not specified → Male ' \
         'Country of origin: not specified → United Kingdom ' \
         'Dna source: not specified → Genomic ' \
         'Volume: not specified → 10 ' \
         'Sample public name: not specified → Human ' \
         'Sample common name: not specified → Human ' \
         'Sample taxon: not specified → 9613 ' \
         'Sample description: not specified → Human ' \
         'Date of sample collection: not specified → 2022-12-12 ' \
         'Concentration: not specified → 20 ' \
         'Supplier name: not specified → eeee ' \
         'Donor: not specified → 12345',
         'Monday 12 July, 2010 10:25', ''],
        ['Updated by Sample Manifest', sample_manifest.name, 'Monday 12 July, 2010 10:25', 'john']
      ]
      visit(history_sample_path(sample_8))
      expect(fetch_table('table#events')).to eq(sample_8_events)

      # A different user logs in and updates the manifest
      login_user new_user

      visit('/sdb/')
      expect(page).to have_title('Sequencescape | Home (Index)')

      click_on 'View all manifests'
      expect(page).to have_title('Sequencescape | Sample Manifests (Index)')

      attach_file('File to upload', 'test/data/test_blank_wells_with_no_blanks_new_data.csv')

      # upload with volume override
      check 'Override previously uploaded samples'
      check 'Overwrite volume'
      click_button 'Upload manifest'
      Delayed::Worker.new.work_off
      expect(page).to have_text('Sample manifest successfully uploaded.')

      visit(history_sample_path(sample_8))
      sample_8_events << [
        'Updated sample metadata',
        'Volume: 10 → 15 ' \
        'Sample taxon: 9613 → 10013 ' \
        'Date of sample collection: 2022-12-12 → 2022-12-08 ' \
        'Supplier name: eeee → eeee_updated',
        'Monday 12 July, 2010 10:25', ''
      ]
      sample_8_events << ['Updated by Sample Manifest', sample_manifest.name, 'Monday 12 July, 2010 10:25', 'jane']
      expect(fetch_table('table#events')).to eq(sample_8_events)
    end

    it 'updates concentration only when overwrite concentration is selected' do
      visit(study_path(study))
      expect(page).to have_title('Sequencescape | Information (Study 1)')

      click_link('Sample Manifests')
      expect(page).to have_title('Sequencescape | Studies (Sample Manifests)')

      expect(page).to have_text('Create manifest for plates')

      expect(PlateBarcode).to receive(:create_barcode).and_return(build(:plate_barcode, barcode: 'SQPD-1234567'))
      sample_manifest = create(:sample_manifest, study:, supplier:, user:)
      sample_manifest.generate

      Delayed::Worker.new.work_off

      sample_manifest.sample_manifest_assets.each_with_index do |sample_manifest_asset, index|
        sample_manifest_asset.update(sanger_sample_id: "sample_#{index}")
      end

      visit('/sdb/')
      expect(page).to have_title('Sequencescape | Home (Index)')

      click_on 'View all manifests'
      expect(page).to have_title('Sequencescape | Sample Manifests (Index)')

      attach_file('File to upload', 'test/data/test_blank_wells.csv')

      click_button 'Upload manifest'
      expect(page).to have_text('Sample manifest successfully uploaded.')

      sample_8 = Sample.find_by!(sanger_sample_id: 'sample_8')
      sample_8_events = [
        ['Message', 'Content', 'Created at', 'Created by'],
        ['Created by Sample Manifest', sample_manifest.name, 'Monday 12 July, 2010 10:25', 'john'],
        ['Updated sample metadata',
         'Gender: not specified → Male ' \
         'Country of origin: not specified → United Kingdom ' \
         'Dna source: not specified → Genomic ' \
         'Volume: not specified → 10 ' \
         'Sample public name: not specified → Human ' \
         'Sample common name: not specified → Human ' \
         'Sample taxon: not specified → 9613 ' \
         'Sample description: not specified → Human ' \
         'Date of sample collection: not specified → 2022-12-12 ' \
         'Concentration: not specified → 20 ' \
         'Supplier name: not specified → eeee ' \
         'Donor: not specified → 12345',
         'Monday 12 July, 2010 10:25', ''],
        ['Updated by Sample Manifest', sample_manifest.name, 'Monday 12 July, 2010 10:25', 'john']
      ]
      visit(history_sample_path(sample_8))
      expect(fetch_table('table#events')).to eq(sample_8_events)

      # A different user logs in and updates the manifest
      login_user new_user

      visit('/sdb/')
      expect(page).to have_title('Sequencescape | Home (Index)')

      click_on 'View all manifests'
      expect(page).to have_title('Sequencescape | Sample Manifests (Index)')

      attach_file('File to upload', 'test/data/test_blank_wells_with_no_blanks_new_data.csv')

      # upload with volume override
      check 'Override previously uploaded samples'
      check 'Overwrite concentration'
      click_button 'Upload manifest'
      Delayed::Worker.new.work_off
      expect(page).to have_text('Sample manifest successfully uploaded.')

      visit(history_sample_path(sample_8))
      sample_8_events << [
        'Updated sample metadata',
        'Sample taxon: 9613 → 10013 ' \
        'Date of sample collection: 2022-12-12 → 2022-12-08 ' \
        'Concentration: 20 → 10 ' \
        'Supplier name: eeee → eeee_updated',
        'Monday 12 July, 2010 10:25', ''
      ]
      sample_8_events << ['Updated by Sample Manifest', sample_manifest.name, 'Monday 12 July, 2010 10:25', 'jane']
      expect(fetch_table('table#events')).to eq(sample_8_events)
    end
  end
end
