# frozen_string_literal: true

# This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2018 Genome Research Ltd.

require 'rails_helper'
require 'helpers/lab_where_client_helper'

RSpec.configure do |c|
  c.include LabWhereClientHelper
end

RSpec.describe LocationReport, type: :model do
  # setup studies
  let(:studies) do
    create_list(:study, 2)
  end
  let(:study_1)               { studies[0] }
  let(:study_2)               { studies[1] }
  let(:study_1_sponsor)       { study_1.study_metadata.faculty_sponsor }
  let(:study_2_sponsor)       { study_2.study_metadata.faculty_sponsor }

  # setup plates
  let(:plate_1) do
    create(
      :plate_with_wells_for_specified_studies,
      studies: [study_1],
      name: 'Plate_1',
      created_at: '2016-02-01 00:00:00'
    )
  end
  let(:plt_1_purpose)         { plate_1.plate_purpose.name }
  let(:plt_1_created)         { plate_1.created_at.strftime('%Y-%m-%d %H:%M:%S') }

  let(:plate_2) do
    create(
      :plate_with_wells_for_specified_studies,
      studies: [study_1, study_2],
      name: 'Plate_2',
      created_at: '2016-06-01 00:00:00'
    )
  end

  let(:plt_2_purpose)         { plate_2.plate_purpose.name }
  let(:plt_2_created)         { plate_2.created_at.strftime('%Y-%m-%d %H:%M:%S') }

  let(:plate_3) do
    create(
      :plate_with_wells_for_specified_studies,
      studies: [study_2],
      name: 'Plate_3',
      created_at: '2016-10-01 00:00:00'
    )
  end
  let(:plt_3_purpose)         { plate_3.plate_purpose.name }
  let(:plt_3_created)         { plate_3.created_at.strftime('%Y-%m-%d %H:%M:%S') }

  let(:headers_line)          { 'ScannedBarcode,HumanBarcode,Type,Created,Location,Service,StudyName,StudyId,FacultySponsor' }
  let(:locn_prefix)           { 'Sanger - Ogilvie - AA209 - Freezer 1' }

  # tests
  context 'when no report type is set' do
    it 'the report is not valid' do
      expect(build(:location_report, report_type: nil)).to_not be_valid
    end
  end

  context 'when testing report generation' do
    let(:location_report) do
      build(
        :location_report,
        report_type: report_type,
        name: name,
        location_barcode: location_barcode,
        faculty_sponsor_ids: faculty_sponsor_ids,
        study_id: study_id,
        start_date: start_date,
        end_date: end_date,
        plate_purpose_ids: plate_purpose_ids,
        barcodes: barcodes
      )
    end
    let(:report_type) { nil }
    let(:name) { nil }
    let(:location_barcode) { nil }
    let(:faculty_sponsor_ids) { nil }
    let(:study_id) { nil }
    let(:start_date) { nil }
    let(:end_date) { nil }
    let(:plate_purpose_ids) { nil }
    let(:barcodes) { nil }

    shared_context 'a successful report' do
      it 'generates the expected report rows' do
        expect(location_report.save).to be_truthy

        lines = []
        location_report.generate_report_rows do |fields|
          lines.push(fields.join(','))
        end

        expect(lines).to match_array(expected_lines)
      end
    end

    context 'by selection on' do
      let(:name) { 'Test_Report_Name' }
      let(:report_type) { :type_selection }

      let(:plt_1_line) { "#{plate_1.machine_barcode},#{plate_1.sanger_human_barcode},#{plt_1_purpose},#{plt_1_created},#{locn_prefix} - Shelf 1,LabWhere,#{study_1.name},#{study_1.id},#{study_1_sponsor.name}" }
      let(:plt_2_line_1) { "#{plate_2.machine_barcode},#{plate_2.sanger_human_barcode},#{plt_2_purpose},#{plt_2_created},#{locn_prefix} - Shelf 2,LabWhere,#{study_1.name},#{study_1.id},#{study_1_sponsor.name}" }
      let(:plt_2_line_2) { "#{plate_2.machine_barcode},#{plate_2.sanger_human_barcode},#{plt_2_purpose},#{plt_2_created},#{locn_prefix} - Shelf 2,LabWhere,#{study_2.name},#{study_2.id},#{study_2_sponsor.name}" }
      let(:plt_3_line) { "#{plate_3.machine_barcode},#{plate_3.sanger_human_barcode},#{plt_3_purpose},#{plt_3_created},#{locn_prefix} - Shelf 3,LabWhere,#{study_2.name},#{study_2.id},#{study_2_sponsor.name}" }

      before(:each) do
        [
          [plate_1.ean13_barcode.to_s, 'Shelf 1', locn_prefix],
          [plate_2.ean13_barcode.to_s, 'Shelf 2', locn_prefix],
          [plate_3.ean13_barcode.to_s, 'Shelf 3', locn_prefix]
        ].each do |lw_barcode, lw_locn_name, lw_locn_parentage|
          stub_lwclient_labware_find_by_bc(lw_barcode: lw_barcode, lw_locn_name: lw_locn_name, lw_locn_parentage: lw_locn_parentage)
        end
      end

      describe 'dates only' do
        let(:start_date) { '2016-01-01 00:00:00' }
        let(:end_date) { '2016-07-01 00:00:00' }
        let(:expected_lines) { [headers_line, plt_1_line, plt_2_line_1, plt_2_line_2] }

        it_behaves_like 'a successful report'
      end

      describe 'dates and a single faculty sponsor' do
        let(:start_date) { '2016-01-01 00:00:00' }
        let(:end_date) { '2016-11-01 00:00:00' }
        let(:faculty_sponsor_ids) { [study_1_sponsor.id] }
        let(:expected_lines) { [headers_line, plt_1_line, plt_2_line_1, plt_2_line_2] }

        it_behaves_like 'a successful report'
      end

      describe 'dates and multiple faculty sponsors' do
        let(:start_date) { '2016-01-01 00:00:00' }
        let(:end_date) { '2016-11-01 00:00:00' }
        let(:faculty_sponsor_ids) { [study_1_sponsor.id, study_2_sponsor.id] }
        let(:expected_lines) { [headers_line, plt_1_line, plt_2_line_1, plt_2_line_2, plt_3_line] }

        it_behaves_like 'a successful report'
      end

      describe 'dates and study' do
        let(:study_id) { study_1.id }
        let(:start_date) { '2016-01-01 00:00:00' }
        let(:end_date) { '2016-11-01 00:00:00' }
        let(:expected_lines) { [headers_line, plt_1_line, plt_2_line_1, plt_2_line_2] }

        it_behaves_like 'a successful report'
      end

      describe 'dates and plate purpose' do
        let(:start_date) { '2016-01-01 00:00:00' }
        let(:end_date) { '2016-11-01 00:00:00' }
        let(:plate_purpose_ids) { [plate_1.plate_purpose.id] }
        let(:expected_lines) { [headers_line, plt_1_line] }

        it_behaves_like 'a successful report'
      end

      describe 'dates and plate purpose for a mixed study plate' do
        let(:start_date) { '2016-01-01 00:00:00' }
        let(:end_date) { '2016-07-01 00:00:00' }
        let(:plate_purpose_ids) { [plate_2.plate_purpose.id] }
        let(:expected_lines) { [headers_line, plt_2_line_1, plt_2_line_2] }

        it_behaves_like 'a successful report'
      end

      describe 'dates and multiple plate purposes' do
        let(:start_date) { '2016-01-01 00:00:00' }
        let(:end_date) { '2016-11-01 00:00:00' }
        let(:plate_purpose_ids) { [plate_2.plate_purpose.id, plate_3.plate_purpose.id] }
        let(:expected_lines) { [headers_line, plt_2_line_1, plt_2_line_2, plt_3_line] }

        it_behaves_like 'a successful report'
      end

      describe 'dates, study and plate purpose' do
        let(:study_id) { study_2.id }
        let(:start_date) { '2016-01-01 00:00:00' }
        let(:end_date) { '2016-11-01 00:00:00' }
        let(:plate_purpose_ids) { [plate_3.plate_purpose.id] }
        let(:expected_lines) { [headers_line, plt_3_line] }

        it_behaves_like 'a successful report'
      end

      describe 'dates, the first study and a plate purpose for a mixed study plate' do
        let(:study_id) { study_1.id }
        let(:start_date) { '2016-01-01 00:00:00' }
        let(:end_date) { '2016-11-01 00:00:00' }
        let(:plate_purpose_ids) { [plate_2.plate_purpose.id] }
        let(:expected_lines) { [headers_line, plt_2_line_1, plt_2_line_2] }

        it_behaves_like 'a successful report'
      end

      describe 'dates, the second study and a plate purpose for a mixed study plate' do
        let(:study_id) { study_2.id }
        let(:start_date) { '2016-01-01 00:00:00' }
        let(:end_date) { '2016-11-01 00:00:00' }
        let(:plate_purpose_ids) { [plate_2.plate_purpose.id] }
        let(:expected_lines) { [headers_line, plt_2_line_1, plt_2_line_2] }

        it_behaves_like 'a successful report'
      end

      describe 'for a plate with no purpose' do
        let(:plate_4) do
          create(
            :plate_with_wells_for_specified_studies,
            studies: [study_1],
            name: 'Plate_4',
            created_at: '2017-02-01 00:00:00',
            purpose: nil
          )
        end

        let(:start_date) { '2017-01-01 00:00:00' }
        let(:end_date) { '2017-03-01 00:00:00' }
        let(:plt_4_created) { plate_4.created_at.strftime('%Y-%m-%d %H:%M:%S') }
        let(:plt_4_line) { "#{plate_4.machine_barcode},#{plate_4.sanger_human_barcode},Unknown,#{plt_4_created},#{locn_prefix} - Shelf 1,LabWhere,#{study_1.name},#{study_1.id},#{study_1_sponsor.name}" }
        let(:expected_lines) { [headers_line, plt_4_line] }

        before(:each) do
          stub_lwclient_labware_find_by_bc(lw_barcode: plate_4.ean13_barcode.to_s, lw_locn_name: 'Shelf 1', lw_locn_parentage: locn_prefix)
        end

        it_behaves_like 'a successful report'
      end

      describe 'barcodes for a single-study plate' do
        let(:barcodes) { [plate_1.machine_barcode] }
        let(:expected_lines) { [headers_line, plt_1_line] }

        it_behaves_like 'a successful report'
      end

      describe 'barcodes for a mixed study plate' do
        let(:barcodes) { [plate_2.machine_barcode] }
        let(:expected_lines) { [headers_line, plt_2_line_1, plt_2_line_2] }

        it_behaves_like 'a successful report'
      end

      describe 'multiple barcodes' do
        let(:barcodes) { [plate_1.machine_barcode, plate_2.machine_barcode, plate_3.machine_barcode] }
        let(:expected_lines) { [headers_line, plt_1_line, plt_2_line_1, plt_2_line_2, plt_3_line] }

        it_behaves_like 'a successful report'
      end

      describe 'multiple barcodes and restricting study' do
        let(:study_id) { study_1.id }
        let(:barcodes) { [plate_1.machine_barcode, plate_3.machine_barcode] }
        let(:expected_lines) { [headers_line, plt_1_line] }

        it_behaves_like 'a successful report'
      end

      describe 'multiple barcodes and a restricting plate purpose' do
        let(:barcodes) { [plate_1.machine_barcode, plate_2.machine_barcode, plate_3.machine_barcode] }
        let(:plate_purpose_ids) { [plate_3.plate_purpose.id] }
        let(:expected_lines) { [headers_line, plt_3_line] }

        it_behaves_like 'a successful report'
      end

      describe 'multiple barcodes and a set of restrictive dates' do
        let(:barcodes) { [plate_1.machine_barcode, plate_2.machine_barcode, plate_3.machine_barcode] }
        let(:start_date) { '2016-05-01 00:00:00' }
        let(:end_date) { '2016-07-01 00:00:00' }
        let(:expected_lines) { [headers_line, plt_2_line_1, plt_2_line_2] }

        it_behaves_like 'a successful report'
      end
    end

    context 'by labwhere location' do
      let(:name) { 'Test_Report_Name' }
      let(:report_type) { :type_labwhere }

      describe 'when no labwares in the location' do
        let(:location_barcode) { 'locn-1-at-lvl-1' }
        let(:expected_lines) { ['No plates found when attempting to generate the report.'] }

        before(:each) do
          stub_lwclient_locn_find_by_bc(locn_barcode: location_barcode, locn_name: 'Shelf 1', locn_parentage: locn_prefix)
          stub_lwclient_locn_children(location_barcode, [])
          stub_lwclient_locn_labwares(location_barcode, [])
        end

        it_behaves_like 'a successful report'
      end

      describe 'when a single labware in the location' do
        let(:location_barcode) { 'locn-1-at-lvl-1' }
        let(:plt_1_line) { "#{plate_1.machine_barcode},#{plate_1.sanger_human_barcode},#{plt_1_purpose},#{plt_1_created},#{locn_prefix} - Shelf 1,LabWhere,#{study_1.name},#{study_1.id},#{study_1_sponsor.name}" }
        let(:expected_lines) { [headers_line, plt_1_line] }

        before(:each) do
          # set up Shelf 1 with no labwares or sub-locations
          p1 = { lw_barcode: plate_1.machine_barcode, lw_locn_name: 'Shelf 1', lw_locn_parentage: locn_prefix }
          stub_lwclient_locn_find_by_bc(locn_barcode: location_barcode, locn_name: 'Shelf 1', locn_parentage: locn_prefix)
          stub_lwclient_locn_children(location_barcode, [])
          stub_lwclient_locn_labwares(location_barcode, [p1])
          stub_lwclient_labware_find_by_bc(p1)
        end

        it_behaves_like 'a successful report'
      end

      describe 'when multiple labwares in same sub-location' do
        let(:location_barcode) { 'locn-1-at-lvl-1' }
        let(:plt_1_line) { "#{plate_1.machine_barcode},#{plate_1.sanger_human_barcode},#{plt_1_purpose},#{plt_1_created},#{locn_prefix} - Shelf 1 - Box 1,LabWhere,#{study_1.name},#{study_1.id},#{study_1_sponsor.name}" }
        let(:plt_2_line_1) { "#{plate_2.machine_barcode},#{plate_2.sanger_human_barcode},#{plt_2_purpose},#{plt_2_created},#{locn_prefix} - Shelf 1 - Box 1,LabWhere,#{study_1.name},#{study_1.id},#{study_1_sponsor.name}" }
        let(:plt_2_line_2) { "#{plate_2.machine_barcode},#{plate_2.sanger_human_barcode},#{plt_2_purpose},#{plt_2_created},#{locn_prefix} - Shelf 1 - Box 1,LabWhere,#{study_2.name},#{study_2.id},#{study_2_sponsor.name}" }
        let(:expected_lines) { [headers_line, plt_1_line, plt_2_line_1, plt_2_line_2] }

        before(:each) do
          # set up Shelf 1 with no labwares and 1 sub-location
          stub_lwclient_locn_find_by_bc(locn_barcode: location_barcode, locn_name: 'Shelf 1', locn_parentage: locn_prefix)
          stub_lwclient_locn_children(location_barcode, [
            {
              locn_barcode: 'locn-1-at-lvl-2',
              locn_name: 'Box 1',
              locn_parentage: locn_prefix + ' - Shelf 1'
            }
          ])
          stub_lwclient_locn_labwares(location_barcode, [])

          # set up Shelf 1 - Box 1 with 2 labwares and no sub-locations
          p1 = { lw_barcode: plate_1.machine_barcode, lw_locn_name: 'Box 1', lw_locn_parentage: locn_prefix + ' - Shelf 1' }
          p2 = { lw_barcode: plate_2.machine_barcode, lw_locn_name: 'Box 1', lw_locn_parentage: locn_prefix + ' - Shelf 1' }
          stub_lwclient_locn_find_by_bc(locn_barcode: 'locn-1-at-lvl-2', locn_name: 'Box 1', locn_parentage: locn_prefix + ' - Shelf 1')
          stub_lwclient_locn_children(location_barcode, [])
          stub_lwclient_locn_labwares(location_barcode, [p1, p2])
          stub_lwclient_labware_find_by_bc(p1)
          stub_lwclient_labware_find_by_bc(p2)
        end

        it_behaves_like 'a successful report'
      end

      describe 'when multiple labwares in different sub-locations ' do
        let(:location_barcode) { 'locn-1-at-lvl-1' }
        let(:plt_1_line) { "#{plate_1.machine_barcode},#{plate_1.sanger_human_barcode},#{plt_1_purpose},#{plt_1_created},#{locn_prefix} - Shelf 1 - Box 1,LabWhere,#{study_1.name},#{study_1.id},#{study_1_sponsor.name}" }
        let(:plt_2_line_1) { "#{plate_2.machine_barcode},#{plate_2.sanger_human_barcode},#{plt_2_purpose},#{plt_2_created},#{locn_prefix} - Shelf 1 - Box 2,LabWhere,#{study_1.name},#{study_1.id},#{study_1_sponsor.name}" }
        let(:plt_2_line_2) { "#{plate_2.machine_barcode},#{plate_2.sanger_human_barcode},#{plt_2_purpose},#{plt_2_created},#{locn_prefix} - Shelf 1 - Box 2,LabWhere,#{study_2.name},#{study_2.id},#{study_2_sponsor.name}" }
        let(:expected_lines) { [headers_line, plt_1_line, plt_2_line_1, plt_2_line_2] }

        before(:each) do
          # set up Shelf 1 with no labwares and two sub-locations
          locn_lvl2_b1 = { locn_barcode: 'locn-1a-at-lvl-2', locn_name: 'Box 1', locn_parentage: locn_prefix + ' - Shelf 1' }
          locn_lvl2_b2 = { locn_barcode: 'locn-1b-at-lvl-2', locn_name: 'Box 2', locn_parentage: locn_prefix + ' - Shelf 1' }
          stub_lwclient_locn_find_by_bc(locn_barcode: location_barcode, locn_name: 'Shelf 1', locn_parentage: locn_prefix)
          stub_lwclient_locn_children(location_barcode, [locn_lvl2_b1, locn_lvl2_b2])
          stub_lwclient_locn_labwares(location_barcode, [])

          # set up Shelf 1 - Box 1 with one labware and no sub-locations
          p1 = { lw_barcode: plate_1.machine_barcode, lw_locn_name: 'Box 1', lw_locn_parentage: locn_prefix + ' - Shelf 1' }
          stub_lwclient_locn_find_by_bc(locn_lvl2_b1)
          stub_lwclient_locn_children(locn_lvl2_b1[:locn_barcode], [])
          stub_lwclient_locn_labwares(locn_lvl2_b1[:locn_barcode], [p1])
          stub_lwclient_labware_find_by_bc(p1)

          # set up Shelf 1 - Box 2 with one labware and no sub-locations
          p2 = { lw_barcode: plate_2.machine_barcode, lw_locn_name: 'Box 2', lw_locn_parentage: locn_prefix + ' - Shelf 1' }
          stub_lwclient_locn_find_by_bc(locn_lvl2_b2)
          stub_lwclient_locn_children(locn_lvl2_b2[:locn_barcode], [])
          stub_lwclient_locn_labwares(locn_lvl2_b2[:locn_barcode], [p2])
          stub_lwclient_labware_find_by_bc(p2)
        end

        it_behaves_like 'a successful report'
      end

      describe 'when multiple labwares at different levels' do
        let(:location_barcode) { 'locn-1-at-lvl-1' }
        let(:plt_1_line) { "#{plate_1.machine_barcode},#{plate_1.sanger_human_barcode},#{plt_1_purpose},#{plt_1_created},#{locn_prefix} - Shelf 1,LabWhere,#{study_1.name},#{study_1.id},#{study_1_sponsor.name}" }
        let(:plt_2_line_1) { "#{plate_2.machine_barcode},#{plate_2.sanger_human_barcode},#{plt_2_purpose},#{plt_2_created},#{locn_prefix} - Shelf 1 - Tray 1,LabWhere,#{study_1.name},#{study_1.id},#{study_1_sponsor.name}" }
        let(:plt_2_line_2) { "#{plate_2.machine_barcode},#{plate_2.sanger_human_barcode},#{plt_2_purpose},#{plt_2_created},#{locn_prefix} - Shelf 1 - Tray 1,LabWhere,#{study_2.name},#{study_2.id},#{study_2_sponsor.name}" }
        let(:plt_3_line) { "#{plate_3.machine_barcode},#{plate_3.sanger_human_barcode},#{plt_3_purpose},#{plt_3_created},#{locn_prefix} - Shelf 1 - Tray 1 - Box 1,LabWhere,#{study_2.name},#{study_2.id},#{study_2_sponsor.name}" }
        let(:expected_lines) { [headers_line, plt_1_line, plt_2_line_1, plt_2_line_2, plt_3_line] }

        before(:each) do
          # set up Shelf 1 with 1 labware and 1 sub-location
          locn_lvl2_t1 = { locn_barcode: 'locn-1-at-lvl-2', locn_name: 'Tray 1', locn_parentage: locn_prefix + ' - Shelf 1' }
          p1 = { lw_barcode: plate_1.machine_barcode, lw_locn_name: 'Shelf 1', lw_locn_parentage: locn_prefix }
          stub_lwclient_locn_find_by_bc(locn_barcode: location_barcode, locn_name: 'Shelf 1', locn_parentage: locn_prefix)
          stub_lwclient_locn_children(location_barcode, [locn_lvl2_t1])
          stub_lwclient_locn_labwares(location_barcode, [p1])
          stub_lwclient_labware_find_by_bc(p1)

          # set up Shelf 1 - Tray 1 with 1 labware and 1 sub-location
          locn_lvl3_b1 = { locn_barcode: 'locn-1-at-lvl-3', locn_name: 'Box 1', locn_parentage: locn_prefix + ' - Shelf 1 - Tray 1' }
          p2 = { lw_barcode: plate_2.machine_barcode, lw_locn_name: 'Tray 1', lw_locn_parentage: locn_prefix + ' - Shelf 1' }
          stub_lwclient_locn_find_by_bc(locn_lvl2_t1)
          stub_lwclient_locn_children(locn_lvl2_t1[:locn_barcode], [locn_lvl3_b1])
          stub_lwclient_locn_labwares(locn_lvl2_t1[:locn_barcode], [p2])
          stub_lwclient_labware_find_by_bc(p2)

          # set up Shelf 1 - Tray 1 - Box 1 with 1 labware and no sub-locations
          p3 = { lw_barcode: plate_3.machine_barcode, lw_locn_name: 'Box 1', lw_locn_parentage: locn_prefix + ' - Shelf 1 - Tray 1' }
          stub_lwclient_locn_find_by_bc(locn_lvl3_b1)
          stub_lwclient_locn_children(locn_lvl3_b1[:locn_barcode], [])
          stub_lwclient_locn_labwares(locn_lvl3_b1[:locn_barcode], [p3])
          stub_lwclient_labware_find_by_bc(p3)
        end

        it_behaves_like 'a successful report'
      end
    end
  end
end
