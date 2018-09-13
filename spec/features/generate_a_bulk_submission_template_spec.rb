# frozen_string_literal: true

require 'rails_helper'

feature 'Generate a bulk submission spreadsheet', js: true, bulk_submission_excel: true do
  let!(:user) { create :user }
  let!(:plate) { create(:plate_with_untagged_wells, well_count: 30) }
  let!(:partial_plate) { create(:plate_with_untagged_wells, well_count: 30) }
  let!(:submission_template) { create :libray_and_sequencing_template }
  let(:date) { Time.current.strftime('%Y%m%d') }
  let(:filename) { "#{plate.human_barcode}_#{partial_plate.human_barcode}_#{date}.xlsx" }

  background do
    BulkSubmissionExcel.configure do |config|
      config.folder = File.join('spec', 'data', 'bulk_submission_excel')
      config.load!
    end
  end

  scenario 'Generate a basic spreadsheet' do
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
end
