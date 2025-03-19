# frozen_string_literal: true

require 'rails_helper'

describe 'Generate a bulk submission spreadsheet', :bulk_submission_excel, :js do
  let!(:user) { create(:user) }
  let!(:plate) { create(:plate_with_untagged_wells, well_count: 30) }

  # We only use two wells of out partial plate in our submission. However we are generating 13
  # to ensure we are only using the specified well. The other two will be ignored.
  let!(:partial_plate) { create(:plate_with_untagged_wells, well_count: 13) }
  let!(:submission_template) { create(:library_and_sequencing_template) }

  let(:iso_date) { Time.current.utc.strftime('%Y%m%d') }
  let(:filename) { "#{plate.human_barcode}_to_#{partial_plate.human_barcode}_#{iso_date}_#{user.login}.xlsx" }

  before do
    BulkSubmissionExcel.configure do |config|
      config.folder = File.join('spec', 'data', 'bulk_submission_excel')
      config.load!
    end
  end

  after { DownloadHelpers.remove_downloads }

  it 'Generate a basic spreadsheet' do
    login_user user
    visit bulk_submissions_path
    fill_in 'Labware barcodes (and wells)', with: "#{plate.human_barcode} #{partial_plate.human_barcode}:A1,A2"
    select(submission_template.name, from: 'Submission Template')
    fill_in('Fragment size required (from)', with: 300)
    click_on 'Generate Template'
    DownloadHelpers.wait_for_download(filename)
    spreadsheet = Roo::Spreadsheet.open(DownloadHelpers.path_to(filename).to_s)
    expect(spreadsheet.sheet(0).cell(1, 1)).to eq('Bulk Submissions Form')
    expect(spreadsheet.sheet(0).last_row).to eq(32 + 2)
  end

  context 'with a primer panel submission' do
    let!(:submission_template) { create(:heron_library_and_sequencing_template) }
    let!(:primer_panel) { create(:primer_panel) }

    it 'populates the primer panel column' do
      # Regression test for https://github.com/sanger/sequencescape/issues/2582
      # Essentially our form was generating a field called primer_panel_name
      # whereas the spreadsheet was populating information from primer_panel.
      login_user user
      visit bulk_submissions_path
      fill_in 'Labware barcodes (and wells)', with: "#{plate.human_barcode} #{partial_plate.human_barcode}:A1,A2"
      select(submission_template.name, from: 'Submission Template')
      fill_in('Fragment size required (from)', with: 300)
      click_on 'Generate Template'
      DownloadHelpers.wait_for_download(filename)
      spreadsheet = Roo::Spreadsheet.open(DownloadHelpers.path_to(filename).to_s)
      expect(spreadsheet.sheet(0).cell(3, 19)).to eq(primer_panel.name)
    end
  end

  context 'with a bait_library submission' do
    let!(:submission_template) { create(:isc_library_and_sequencing_template) }
    let!(:bait_library) { create(:bait_library) }

    it 'populates the primer panel column' do
      # Regression test for https://github.com/sanger/sequencescape/issues/2582
      # Essentially our form was generating a field called bait_library_name
      # whereas the spreadsheet was populating information from bait_library.
      login_user user
      visit bulk_submissions_path
      fill_in 'Labware barcodes (and wells)', with: "#{plate.human_barcode} #{partial_plate.human_barcode}:A1,A2"
      select(submission_template.name, from: 'Submission Template')
      fill_in('Fragment size required (from)', with: 300)
      click_on 'Generate Template'
      DownloadHelpers.wait_for_download(filename)
      spreadsheet = Roo::Spreadsheet.open(DownloadHelpers.path_to(filename).to_s)
      expect(spreadsheet.sheet(0).cell(3, 13)).to eq(bait_library.name)
    end
  end
end
