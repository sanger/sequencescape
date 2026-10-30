# frozen_string_literal: true

require 'rails_helper'

# The whole flow of a compound sample plate manifest, e.g. Kinnex, through the
# UI with the feature flag on: creating the manifest, then uploading it and
# finding each component sample's tag on its plate's compound sample page.
RSpec.describe 'Compound sample plate manifest', :sample_manifest do
  let(:user) { create(:admin) }
  let(:tag_group) do
    handler = SequencescapeExcel::SpecialisedField::ComponentTagSequence
    create(:tag_group, name: handler::TAG_GROUP_NAME, tag_count: 3)
  end

  before do
    SampleManifestExcel.configure do |config|
      config.folder = File.join('spec', 'data', 'sample_manifest_excel')
      config.tag_group = 'My Magic Tag Group'
      config.load!
    end
    Flipper.enable(:y26_147_1_enable_compound_sample_plate_manifests)
    tag_group
    login_user(user)
  end

  after { SampleManifestExcel.reset! }

  context 'when creating a manifest' do
    let!(:study) { create(:study) }
    let!(:supplier) { create(:supplier) }
    let!(:printer) { create(:barcode_printer) }

    before do
      stub_request(:post, LabelPrinter::PmbClient.print_job_url)
      visit(study_path(study))
      click_link('Sample Manifests')
      click_link('Create manifest for compound sample plates')
      select('Kinnex Compound Sample Plate', from: 'Template')
      select(study.name, from: 'Study')
      select(supplier.name, from: 'Supplier')
      fill_in('Plates required', with: '2')
      select(printer.name, from: 'Barcode printer')
      click_button('Create manifest and print labels')
    end

    it 'creates the manifest' do
      expect(page).to have_text('Upload a Sample Manifest')
    end

    it 'prints one label per plate' do
      message = "Your 2 label(s) have been sent to printer #{printer.name}"
      expect(page).to have_text(message)
    end
  end

  context 'when uploading a filled manifest', :un_delay_jobs do
    let(:test_file) { 'compound_sample_plate_manifest.xlsx' }
    let(:download) do
      columns = SampleManifestExcel.configuration.columns
      build(
        :test_download_compound_plates,
        columns: columns.kinnex_compound_sample_plate.dup,
        count: 2,
        components_per_tube: [2, 1]
      )
    end
    let(:manifest) { download.worksheet.sample_manifest }
    let(:first_plate_rows) do
      manifest.sample_manifest_assets.group_by(&:asset).values.first
    end
    let(:first_plate) { first_plate_rows.first.asset.plate }
    # The filled rows of a plate take the tags in order.
    let(:expected_component_rows) do
      tags = tag_group.tags.order(:map_id)
      first_plate_rows.first(2).zip(tags).map do |row, tag|
        a_string_including(row.sanger_sample_id, "#{tag.map_id} (#{tag.oligo})")
      end
    end

    def open_compound_sample_page(plate)
      visit(plate_path(plate))
      within('#plate-samples-table tbody') { find('a').click }
    end

    def component_rows
      panel = find('h3', text: 'Component Samples').find(:xpath, '..')
      panel.all('tbody tr').map(&:text)
    end

    before do
      create(:insdc_country, name: 'United Kingdom')
      download.save(test_file)
      visit(new_sample_manifest_upload_with_tag_sequence_path)
      attach_file('File to upload', Rails.root.join(test_file))
      click_button('Upload manifest')
    end

    after { FileUtils.rm_f(test_file) }

    it 'uploads the manifest' do
      expect(page).to have_text('Sample manifest successfully uploaded.')
    end

    it 'shows the tag of each component sample of a plate' do
      open_compound_sample_page(first_plate)
      expect(component_rows).to match_array(expected_component_rows)
    end
  end
end
