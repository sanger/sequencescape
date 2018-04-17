# frozen_string_literal: true

# This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2018 Genome Research Ltd.

require 'rails_helper'

feature 'Creating location reports from selected criteria' do
  let(:user) { create(:admin) }
  let!(:study_1) { create(:study) }
  let!(:study_2) { create(:study) }
  let(:study_1_faculty_sponsor) { study_1.study_metadata.faculty_sponsor.name }
  let!(:plate_1) do
    create(
      :plate_with_wells_for_specified_studies,
      studies: [study_1],
      name: 'Plate_1',
      created_at: '2016-02-01 00:00:00'
    )
  end
  let(:plt_1_purpose) { plate_1.plate_purpose.name }

  let!(:plate_2) do
    create(
      :plate_with_wells_for_specified_studies,
      studies: [study_1],
      name: 'Plate_2',
      created_at: '2016-08-01 00:00:00'
    )
  end

  let!(:plate_3) do
    create(
      :plate_with_wells_for_specified_studies,
      studies: [study_2],
      name: 'Plate_3',
      created_at: '2016-10-01 00:00:00'
    )
  end

  scenario 'with a start and end date selected' do
    login_user user
    visit location_reports_path
    expect(page).to have_content 'Plate Location Reports'
    within('#new_report_from_selection') do
      fill_in 'name', with: 'Test report'
      fill_in 'location_report_start_date', with: '01/01/2016'
      fill_in 'location_report_end_date', with: '01/09/2016'
    end
    click_button('Create report from selection')
    expect(page).to have_content 'Your report has been requested and will be listed at the bottom of this page when complete.'
  end

  scenario 'with a faculty sponsor and start and end date selected' do
    login_user user
    visit location_reports_path
    expect(page).to have_content 'Plate Location Reports'
    within('#new_report_from_selection') do
      fill_in 'name', with: 'Test report'
      select(study_1_faculty_sponsor, from: 'location_report_faculty_sponsor_ids')
      fill_in 'location_report_start_date', with: '01/01/2016'
      fill_in 'location_report_end_date', with: '01/11/2016'
    end
    click_button('Create report from selection')
    expect(page).to have_content 'Your report has been requested and will be listed at the bottom of this page when complete.'
  end

  scenario 'with a study, start and end date selected' do
    login_user user
    visit location_reports_path
    expect(page).to have_content 'Plate Location Reports'
    within('#new_report_from_selection') do
      fill_in 'name', with: 'Test report'
      select(study_1.name, from: 'location_report_study_id')
      fill_in 'location_report_start_date', with: '01/01/2016'
      fill_in 'location_report_end_date', with: '01/09/2016'
    end
    click_button('Create report from selection')
    expect(page).to have_content 'Your report has been requested and will be listed at the bottom of this page when complete.'
  end

  scenario 'with a start and end date and a purpose seleced' do
    login_user user
    visit location_reports_path
    expect(page).to have_content 'Plate Location Reports'
    within('#new_report_from_selection') do
      fill_in 'name', with: 'Test report'
      fill_in 'location_report_start_date', with: '01/01/2016'
      fill_in 'location_report_end_date', with: '01/09/2016'
      select(plt_1_purpose, from: 'location_report_plate_purpose_ids')
    end
    click_button('Create report from selection')
    expect(page).to have_content 'Your report has been requested and will be listed at the bottom of this page when complete.'
  end

  scenario 'with a faculty_sponsor, study, start and end date and a purpose selected' do
    login_user user
    visit location_reports_path
    expect(page).to have_content 'Plate Location Reports'
    within('#new_report_from_selection') do
      fill_in 'name', with: 'Test report'
      select(study_1_faculty_sponsor, from: 'location_report_faculty_sponsor_ids')
      select(study_1.name, from: 'location_report_study_id')
      fill_in 'location_report_start_date', with: '01/01/2016'
      fill_in 'location_report_end_date', with: '01/09/2016'
      select(plt_1_purpose, from: 'location_report_plate_purpose_ids')
    end
    click_button('Create report from selection')
    expect(page).to have_content 'Your report has been requested and will be listed at the bottom of this page when complete.'
  end

  scenario 'without a start date selected' do
    login_user user
    visit location_reports_path
    expect(page).to have_content 'Plate Location Reports'
    within('#new_report_from_selection') do
      fill_in 'name', with: 'Test report'
      select(study_1.name, from: 'location_report_study_id')
      fill_in 'location_report_end_date', with: '01/09/2016'
    end
    click_button('Create report from selection')
    expect(page).to have_content 'Failed to create report: Start date Both start and end date are required if either one is used.'
  end

  scenario 'with a single valid barcode' do
    login_user user
    visit location_reports_path
    expect(page).to have_content 'Plate Location Reports'
    within('#new_report_from_selection') do
      fill_in 'name', with: 'Test report'
      fill_in 'location_report_barcodes_text', with: plate_1.machine_barcode
    end
    click_button('Create report from selection')
    expect(page).to have_content 'Your report has been requested and will be listed at the bottom of this page when complete.'
  end

  scenario 'with a single invalid barcode' do
    login_user user
    visit location_reports_path
    expect(page).to have_content 'Plate Location Reports'
    within('#new_report_from_selection') do
      fill_in 'name', with: 'Test report'
      fill_in 'location_report_barcodes_text', with: 'INVALIDBC'
    end
    click_button('Create report from selection')
    expect(page).to have_content 'Barcodes text Invalid barcodes found, no report generated: INVALIDBC'
  end

  scenario 'with a mix of valid and invalid barcodes' do
    login_user user
    visit location_reports_path
    expect(page).to have_content 'Plate Location Reports'
    within('#new_report_from_selection') do
      fill_in 'name', with: 'Test report'
      fill_in 'location_report_barcodes_text', with: "#{plate_1.machine_barcode} INVALIDBC"
    end
    click_button('Create report from selection')
    expect(page).to have_content 'Failed to create report: Barcodes text Invalid barcodes found, no report generated: INVALIDBC'
  end

  scenario 'with selection criteria that find no results' do
    login_user user
    visit location_reports_path
    expect(page).to have_content 'Plate Location Reports'
    within('#new_report_from_selection') do
      fill_in 'name', with: 'Test report'
      select(study_1.name, from: 'location_report_study_id')
      fill_in 'location_report_start_date', with: '01/01/2017'
      fill_in 'location_report_end_date', with: '01/09/2017'
      select(plt_1_purpose, from: 'location_report_plate_purpose_ids')
    end
    click_button('Create report from selection')
    expect(page).to have_content 'Failed to create report: That selection returns no plates, no report generated.'
  end
end
