# frozen_string_literal: true

require 'rails_helper'
require 'support/lab_where_client_helper'

RSpec.configure { |c| c.include LabWhereClientHelper }

describe 'Location reports' do
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

  let!(:tube_1) do
    create(
      :sample_tube,
      study: study_1,
      name: 'Tube_1',
      created_at: '2016-08-01 00:00:00'
    )
  end
  let(:tube_1_purpose) { tube_1.purpose.name }

  describe 'by selection' do
    it 'with a start and end date selected' do
      login_user user
      visit location_reports_path
      expect(page).to have_content 'Labware Location Reports'
      within('#new_report_from_selection') do
        fill_in 'Report name', with: 'Test report'
        fill_in 'Start date', with: '01/01/2016'
        fill_in 'End date', with: '01/09/2016'
      end
      click_button('Create report from selection')
      expect(
        page
      ).to have_content 'Your report has been requested and will be listed at the bottom of this page when complete.'
    end

    it 'with a faculty sponsor and start and end date selected' do
      login_user user
      visit location_reports_path
      expect(page).to have_content 'Labware Location Reports'
      within('#new_report_from_selection') do
        fill_in 'Report name', with: 'Test report'
        select(study_1_faculty_sponsor, from: 'Faculty Sponsors (can select multiple)')
        fill_in 'Start date', with: '01/01/2016'
        fill_in 'End date', with: '01/11/2016'
      end
      click_button('Create report from selection')
      expect(
        page
      ).to have_content 'Your report has been requested and will be listed at the bottom of this page when complete.'
    end

    it 'with a study, start and end date selected' do
      login_user user
      visit location_reports_path
      expect(page).to have_content 'Labware Location Reports'
      within('#new_report_from_selection') do
        fill_in 'Report name', with: 'Test report'
        select(study_1.name, from: 'Study')
        fill_in 'Start date', with: '01/01/2016'
        fill_in 'End date', with: '01/09/2016'
      end
      click_button('Create report from selection')
      expect(
        page
      ).to have_content 'Your report has been requested and will be listed at the bottom of this page when complete.'
    end

    it 'with a start and end date and a plate purpose seleced' do
      login_user user
      visit location_reports_path
      expect(page).to have_content 'Labware Location Reports'
      within('#new_report_from_selection') do
        fill_in 'Report name', with: 'Test report'
        fill_in 'Start date', with: '01/01/2016'
        fill_in 'End date', with: '01/09/2016'
        select(plt_1_purpose, from: 'Labware purposes (can select multiple)')
      end
      click_button('Create report from selection')
      expect(
        page
      ).to have_content 'Your report has been requested and will be listed at the bottom of this page when complete.'
    end

    it 'with a start and end date and a tube purpose seleced' do
      login_user user
      visit location_reports_path
      expect(page).to have_content 'Labware Location Reports'
      within('#new_report_from_selection') do
        fill_in 'Report name', with: 'Test report'
        fill_in 'Start date', with: '01/01/2016'
        fill_in 'End date', with: '01/09/2016'
        select(tube_1_purpose, from: 'Labware purposes (can select multiple)')
      end
      click_button('Create report from selection')
      expect(
        page
      ).to have_content 'Your report has been requested and will be listed at the bottom of this page when complete.'
    end

    it 'with a faculty_sponsor, study, start and end date and a purpose selected' do
      login_user user
      visit location_reports_path
      expect(page).to have_content 'Labware Location Reports'
      within('#new_report_from_selection') do
        fill_in 'Report name', with: 'Test report'
        select(study_1_faculty_sponsor, from: 'Faculty Sponsors (can select multiple)')
        select(study_1.name, from: 'Study')
        fill_in 'Start date', with: '01/01/2016'
        fill_in 'End date', with: '01/09/2016'
        select(plt_1_purpose, from: 'Labware purposes (can select multiple)')
      end
      click_button('Create report from selection')
      expect(
        page
      ).to have_content 'Your report has been requested and will be listed at the bottom of this page when complete.'
    end

    it 'without a start date selected' do
      login_user user
      visit location_reports_path
      expect(page).to have_content 'Labware Location Reports'
      within('#new_report_from_selection') do
        fill_in 'Report name', with: 'Test report'
        select(study_1.name, from: 'Study')
        fill_in 'End date', with: '01/09/2016'
      end
      click_button('Create report from selection')
      expect(
        page
        # rubocop:todo Layout/LineLength
      ).to have_content 'Failed to create report: Start date Both start and end date are required if either one is used.'
      # rubocop:enable Layout/LineLength
    end

    it 'with a single valid barcode' do
      login_user user
      visit location_reports_path
      expect(page).to have_content 'Labware Location Reports'
      within('#new_report_from_selection') do
        fill_in 'Report name', with: 'Test report'
        fill_in 'List of Barcodes (separated by new lines, spaces or commas)', with: plate_1.machine_barcode
      end
      click_button('Create report from selection')
      expect(
        page
      ).to have_content 'Your report has been requested and will be listed at the bottom of this page when complete.'
    end

    it 'with selection criteria that find no results' do
      login_user user
      visit location_reports_path
      expect(page).to have_content 'Labware Location Reports'
      within('#new_report_from_selection') do
        fill_in 'Report name', with: 'Test report'
        select(study_1.name, from: 'Study')
        fill_in 'Start date', with: '01/01/2017'
        fill_in 'End date', with: '01/09/2017'
        select(plt_1_purpose, from: 'Labware purposes (can select multiple)')
      end
      click_button('Create report from selection')
      expect(page).to have_content 'Failed to create report: That selection returns no labware, no report generated.'
    end
  end

  describe 'by labwhere location' do
    let(:labwhere_locn_prefix) { 'Building - Room - Freezer' }

    it 'with a valid labwhere location barcode' do
      # set up LabWhere stubs
      labwhere_locn_bc = 'lw-mylocn-123'
      p1 = { lw_barcode: plate_1.machine_barcode, lw_locn_name: 'Shelf 1', lw_locn_parentage: labwhere_locn_prefix }
      stub_lwclient_locn_find_by_bc(
        locn_barcode: labwhere_locn_bc,
        locn_name: 'Shelf 1',
        locn_parentage: labwhere_locn_prefix
      )
      stub_lwclient_locn_children(labwhere_locn_bc, [])
      stub_lwclient_locn_labwares(labwhere_locn_bc, [p1])
      stub_lwclient_labware_find_by_bc(p1)

      login_user user
      visit location_reports_path
      expect(page).to have_content 'Labware Location Reports'
      within('#new_report_from_labwhere_location') do
        fill_in 'Report name', with: 'Test report'
        fill_in 'LabWhere location barcode', with: labwhere_locn_bc
      end
      click_button('Create report from labwhere')
      expect(
        page
      ).to have_content 'Your report has been requested and will be listed at the bottom of this page when complete.'
    end

    it 'with an invalid labwhere location barcode' do
      # set up LabWhere stubs
      labwhere_locn_bc = 'lw-fake-locn'
      stub_lwclient_locn_find_by_bc(locn_barcode: labwhere_locn_bc, locn_name: nil, locn_parentage: nil)

      login_user user
      visit location_reports_path
      expect(page).to have_content 'Labware Location Reports'
      within('#new_report_from_labwhere_location') do
        fill_in 'Report name', with: 'Test report'
        fill_in 'LabWhere location barcode', with: labwhere_locn_bc
      end
      click_button('Create report from labwhere')
      expect(
        page
        # rubocop:todo Layout/LineLength
      ).to have_content 'Failed to create report: LabWhere location not found, please scan or enter a valid location barcode.'
      # rubocop:enable Layout/LineLength
    end
  end
end
