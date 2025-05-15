# frozen_string_literal: true

require 'rails_helper'
require 'support/lab_where_client_helper'

RSpec.configure { |c| c.include LabWhereClientHelper }

RSpec.describe LocationReport do
  # setup studies
  let(:studies) { create_list(:study, 2) }
  let(:study_1) { studies[0] }
  let(:study_2) { studies[1] }
  let(:study_1_sponsor) { study_1.study_metadata.faculty_sponsor }
  let(:study_2_sponsor) { study_2.study_metadata.faculty_sponsor }
  let(:user) { create(:user, login: 'test') }

  # setup plates
  let(:plate_1) do
    create(
      :plate_with_wells_for_specified_studies,
      studies: [study_1],
      name: 'Plate_1',
      created_at: '2016-02-01 12:00:00'
    )
  end
  let!(:plt_1_asset_audit) do
    create(
      :asset_audit,
      asset: plate_1,
      created_at: Time.zone.parse('June 15, 2020 15:41'),
      key: 'slf_receive_plates',
      message: "Process '...' performed on instrument Reception fridge"
    )
    create(
      :asset_audit,
      asset: plate_1,
      created_at: Time.zone.parse('June 16, 2020 15:42'),
      key: 'slf_receive_plates',
      message: "Process '...' performed on instrument Reception fridge"
    )
    # return the last audit only
  end
  let(:plt_1_purpose) { plate_1.plate_purpose.name }
  let(:plt_1_created) { plate_1.created_at.strftime('%Y-%m-%d %H:%M:%S') }
  let(:plt_1_received_date) { plt_1_asset_audit.created_at.strftime('%Y-%m-%d %H:%M:%S') }

  # add retention instruction metadata to plate 1 custom metadatum collection
  let(:retention_key) { 'retention_instruction' }
  let(:retention_value) { 'Long term storage' }
  let(:plate_1_custom_metadatum_collection) { create(:custom_metadatum_collection, asset: plate_1, user: user) }
  let(:plate_1_custom_metadatum) do
    create(
      :custom_metadatum,
      custom_metadatum_collection: plate_1_custom_metadatum_collection,
      key: retention_key,
      value: retention_value
    )
  end

  let(:plate_2) do
    create(
      :plate_with_wells_for_specified_studies,
      studies: [study_1, study_2],
      name: 'Plate_2',
      created_at: '2016-06-01 12:00:00'
    )
  end

  let(:plt_2_purpose) { plate_2.plate_purpose.name }
  let(:plt_2_created) { plate_2.created_at.strftime('%Y-%m-%d %H:%M:%S') }
  let(:plt_2_received_date) { 'Unknown' }

  let(:plate_3) do
    create(
      :plate_with_wells_for_specified_studies,
      studies: [study_2],
      name: 'Plate_3',
      created_at: '2016-10-01 12:00:00'
    )
  end
  let(:plt_3_purpose) { plate_3.plate_purpose.name }
  let(:plt_3_created) { plate_3.created_at.strftime('%Y-%m-%d %H:%M:%S') }
  let(:plt_3_received_date) { 'Unknown' }

  # add retention instruction metadata to plate 3 custom metadatum collection
  let(:plate_3_custom_metadatum_collection) { create(:custom_metadatum_collection, asset: plate_3, user: user) }
  let(:plate_3_custom_metadatum) do
    create(
      :custom_metadatum,
      custom_metadatum_collection: plate_3_custom_metadatum_collection,
      key: retention_key,
      value: retention_value
    )
  end

  let(:headers_line) do
    %w[
      ScannedBarcode
      HumanBarcode
      Type
      Created
      ReceivedDate
      Location
      Service
      RetentionInstructions
      StudyName
      StudyId
      FacultySponsor
    ].join(',')
  end
  let(:locn_prefix) { 'Sanger - Ogilvie - AA209 - Freezer 1' }

  context 'location reports' do
    let(:location_report) do
      build(
        :location_report,
        report_type:,
        name:,
        location_barcode:,
        faculty_sponsor_ids:,
        study_id:,
        start_date:,
        end_date:,
        plate_purpose_ids:,
        barcodes:
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

    describe 'validations' do
      context 'when no report type is set' do
        let(:name) { 'Test_report' }

        it 'the report is not valid' do
          expect(location_report).not_to be_valid
        end
      end

      context 'when none of the selection criteria are selected' do
        let(:name) { 'Test_report' }
        let(:report_type) { 'type_selection' }

        it 'the report is not valid' do
          expect(location_report).not_to be_valid
        end
      end

      context 'when no plates are returned' do
        let(:name) { 'Test_report' }
        let(:report_type) { 'type_selection' }
        let(:start_date) { '2015-01-01 00:00:00' }
        let(:end_date) { '2015-07-01 00:00:00' }

        it 'the report is not valid' do
          expect(location_report).not_to be_valid
        end
      end

      context 'when selecting using dates' do
        let(:name) { 'Test_report' }
        let(:report_type) { 'type_selection' }

        it 'is not valid if there is an end date but no start date' do
          location_report.end_date = '2016-07-01 00:00:00'
          expect(location_report).not_to be_valid
        end

        it 'is not valid if there is a start date but no end date' do
          location_report.start_date = '2016-06-01 00:00:00'
          expect(location_report).not_to be_valid
        end

        it 'is not valid if the start date is after the end date' do
          location_report.start_date = '2016-08-01 00:00:00'
          location_report.end_date = '2016-07-01 00:00:00'
          expect(location_report).not_to be_valid
        end

        it 'is valid for the start date to be the same as the end date' do
          plate_1
          location_report.start_date = '2016-02-01 00:00:00'
          location_report.end_date = '2016-02-01 00:00:00'
          expect(location_report).to be_valid
        end

        it 'is not valid if the dates do not find any plates' do
          location_report.start_date = '2016-07-01 00:00:00'
          location_report.end_date = '2016-07-02 00:00:00'
          expect(location_report).not_to be_valid
        end
      end
    end

    describe 'report generation' do
      shared_examples 'a successful report' do
        it 'generates the expected report rows' do
          expect(location_report.save).to be_truthy

          lines = []
          location_report.generate_report_rows { |fields| lines.push(fields.join(',')) }

          expect(lines).to match_array(expected_lines)
        end

        it 'generates the report' do
          expect { location_report.generate! }.not_to raise_error
        end
      end

      context 'by selection on' do
        let(:name) { 'Test_Report_Name' }
        let(:report_type) { :type_selection }

        let(:plt_1_line) do
          # rubocop:todo Layout/LineLength
          "#{plate_1.machine_barcode},#{plate_1.human_barcode},#{plt_1_purpose},#{plt_1_created},#{plt_1_received_date},#{locn_prefix} - Shelf 1,LabWhere,#{retention_value},#{study_1.name},#{study_1.id},#{study_1_sponsor.name}"
          # rubocop:enable Layout/LineLength
        end
        let(:plt_2_line_1) do
          # rubocop:todo Layout/LineLength
          "#{plate_2.machine_barcode},#{plate_2.human_barcode},#{plt_2_purpose},#{plt_2_created},#{plt_2_received_date},#{locn_prefix} - Shelf 2,LabWhere,Unknown,#{study_1.name},#{study_1.id},#{study_1_sponsor.name}"
          # rubocop:enable Layout/LineLength
        end
        let(:plt_2_line_2) do
          # rubocop:todo Layout/LineLength
          "#{plate_2.machine_barcode},#{plate_2.human_barcode},#{plt_2_purpose},#{plt_2_created},#{plt_2_received_date},#{locn_prefix} - Shelf 2,LabWhere,Unknown,#{study_2.name},#{study_2.id},#{study_2_sponsor.name}"
          # rubocop:enable Layout/LineLength
        end
        let(:plt_3_line) do
          # rubocop:todo Layout/LineLength
          "#{plate_3.machine_barcode},#{plate_3.human_barcode},#{plt_3_purpose},#{plt_3_created},#{plt_3_received_date},#{locn_prefix} - Shelf 3,LabWhere,#{retention_value},#{study_2.name},#{study_2.id},#{study_2_sponsor.name}"
          # rubocop:enable Layout/LineLength
        end

        before do
          [
            [plate_1.machine_barcode.to_s, 'Shelf 1', locn_prefix],
            [plate_2.machine_barcode.to_s, 'Shelf 2', locn_prefix],
            [plate_3.machine_barcode.to_s, 'Shelf 3', locn_prefix]
          ].each do |lw_barcode, lw_locn_name, lw_locn_parentage|
            stub_lwclient_labware_find_by_bc(lw_barcode:, lw_locn_name:, lw_locn_parentage:)
          end

          plate_1_custom_metadatum
          plate_3_custom_metadatum
        end

        context 'dates only' do
          let(:start_date) { '2016-01-01 00:00:00' }
          let(:end_date) { '2016-07-01 00:00:00' }
          let(:expected_lines) { [headers_line, plt_1_line, plt_2_line_1, plt_2_line_2] }

          it_behaves_like 'a successful report'
        end

        context 'dates and a single faculty sponsor' do
          let(:start_date) { '2016-01-01 00:00:00' }
          let(:end_date) { '2016-11-01 00:00:00' }
          let(:faculty_sponsor_ids) { [study_1_sponsor.id] }
          let(:expected_lines) { [headers_line, plt_1_line, plt_2_line_1, plt_2_line_2] }

          it_behaves_like 'a successful report'
        end

        context 'dates and multiple faculty sponsors' do
          let(:start_date) { '2016-01-01 00:00:00' }
          let(:end_date) { '2016-11-01 00:00:00' }
          let(:faculty_sponsor_ids) { [study_1_sponsor.id, study_2_sponsor.id] }
          let(:expected_lines) { [headers_line, plt_1_line, plt_2_line_1, plt_2_line_2, plt_3_line] }

          it_behaves_like 'a successful report'
        end

        context 'dates and study' do
          let(:study_id) { study_1.id }
          let(:start_date) { '2016-01-01 00:00:00' }
          let(:end_date) { '2016-11-01 00:00:00' }
          let(:expected_lines) { [headers_line, plt_1_line, plt_2_line_1, plt_2_line_2] }

          it_behaves_like 'a successful report'
        end

        context 'dates and plate purpose' do
          let(:start_date) { '2016-01-01 00:00:00' }
          let(:end_date) { '2016-11-01 00:00:00' }
          let(:plate_purpose_ids) { [plate_1.plate_purpose.id] }
          let(:expected_lines) { [headers_line, plt_1_line] }

          it_behaves_like 'a successful report'
        end

        context 'dates and plate purpose for a mixed study plate' do
          let(:start_date) { '2016-01-01 00:00:00' }
          let(:end_date) { '2016-07-01 00:00:00' }
          let(:plate_purpose_ids) { [plate_2.plate_purpose.id] }
          let(:expected_lines) { [headers_line, plt_2_line_1, plt_2_line_2] }

          it_behaves_like 'a successful report'
        end

        context 'dates and multiple plate purposes' do
          let(:start_date) { '2016-01-01 00:00:00' }
          let(:end_date) { '2016-11-01 00:00:00' }
          let(:plate_purpose_ids) { [plate_2.plate_purpose.id, plate_3.plate_purpose.id] }
          let(:expected_lines) { [headers_line, plt_2_line_1, plt_2_line_2, plt_3_line] }

          it_behaves_like 'a successful report'
        end

        context 'dates, study and plate purpose' do
          let(:study_id) { study_2.id }
          let(:start_date) { '2016-01-01 00:00:00' }
          let(:end_date) { '2016-11-01 00:00:00' }
          let(:plate_purpose_ids) { [plate_3.plate_purpose.id] }
          let(:expected_lines) { [headers_line, plt_3_line] }

          it_behaves_like 'a successful report'
        end

        context 'dates, the first study and a plate purpose for a mixed study plate' do
          let(:study_id) { study_1.id }
          let(:start_date) { '2016-01-01 00:00:00' }
          let(:end_date) { '2016-11-01 00:00:00' }
          let(:plate_purpose_ids) { [plate_2.plate_purpose.id] }
          let(:expected_lines) { [headers_line, plt_2_line_1, plt_2_line_2] }

          it_behaves_like 'a successful report'
        end

        context 'dates, the second study and a plate purpose for a mixed study plate' do
          let(:study_id) { study_2.id }
          let(:start_date) { '2016-01-01 00:00:00' }
          let(:end_date) { '2016-11-01 00:00:00' }
          let(:plate_purpose_ids) { [plate_2.plate_purpose.id] }
          let(:expected_lines) { [headers_line, plt_2_line_1, plt_2_line_2] }

          it_behaves_like 'a successful report'
        end

        context 'for a plate with no purpose' do
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
          let(:plt_4_received_date) { 'Unknown' }
          let(:plt_4_line) do
            # rubocop:todo Layout/LineLength
            "#{plate_4.machine_barcode},#{plate_4.human_barcode},Unknown,#{plt_4_created},#{plt_4_received_date},#{locn_prefix} - Shelf 1,LabWhere,Unknown,#{study_1.name},#{study_1.id},#{study_1_sponsor.name}"
            # rubocop:enable Layout/LineLength
          end
          let(:expected_lines) { [headers_line, plt_4_line] }

          before do
            stub_lwclient_labware_find_by_bc(
              lw_barcode: plate_4.machine_barcode.to_s,
              lw_locn_name: 'Shelf 1',
              lw_locn_parentage: locn_prefix
            )
          end

          it_behaves_like 'a successful report'
        end

        context 'barcodes for a single-study plate' do
          let(:barcodes) { [plate_1.machine_barcode] }
          let(:expected_lines) { [headers_line, plt_1_line] }

          it_behaves_like 'a successful report'
        end

        context 'barcodes for a mixed study plate' do
          let(:barcodes) { [plate_2.machine_barcode] }
          let(:expected_lines) { [headers_line, plt_2_line_1, plt_2_line_2] }

          it_behaves_like 'a successful report'
        end

        context 'multiple barcodes' do
          let(:barcodes) { [plate_1.machine_barcode, plate_2.machine_barcode, plate_3.machine_barcode] }
          let(:expected_lines) { [headers_line, plt_1_line, plt_2_line_1, plt_2_line_2, plt_3_line] }

          it_behaves_like 'a successful report'
        end

        context 'multiple barcodes and restricting study' do
          let(:study_id) { study_1.id }
          let(:barcodes) { [plate_1.machine_barcode, plate_3.machine_barcode] }
          let(:expected_lines) { [headers_line, plt_1_line] }

          it_behaves_like 'a successful report'
        end

        context 'multiple barcodes and a restricting plate purpose' do
          let(:barcodes) { [plate_1.machine_barcode, plate_2.machine_barcode, plate_3.machine_barcode] }
          let(:plate_purpose_ids) { [plate_3.plate_purpose.id] }
          let(:expected_lines) { [headers_line, plt_3_line] }

          it_behaves_like 'a successful report'
        end

        context 'multiple barcodes and a set of restrictive dates' do
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

          before do
            stub_lwclient_locn_find_by_bc(
              locn_barcode: location_barcode,
              locn_name: 'Shelf 1',
              locn_parentage: locn_prefix
            )
            stub_lwclient_locn_children(location_barcode, [])
            stub_lwclient_locn_labwares(location_barcode, [])

            plate_1_custom_metadatum
            plate_3_custom_metadatum
          end

          it_behaves_like 'a successful report'
        end

        describe 'when a single labware in the location' do
          let(:location_barcode) { 'locn-1-at-lvl-1' }
          let(:plt_1_line) do
            # rubocop:todo Layout/LineLength
            "#{plate_1.machine_barcode},#{plate_1.human_barcode},#{plt_1_purpose},#{plt_1_created},#{plt_1_received_date},#{locn_prefix} - Shelf 1,LabWhere,#{retention_value},#{study_1.name},#{study_1.id},#{study_1_sponsor.name}"
            # rubocop:enable Layout/LineLength
          end
          let(:expected_lines) { [headers_line, plt_1_line] }

          before do
            # set up Shelf 1 with no labwares or sub-locations
            p1 = { lw_barcode: plate_1.machine_barcode, lw_locn_name: 'Shelf 1', lw_locn_parentage: locn_prefix }
            stub_lwclient_locn_find_by_bc(
              locn_barcode: location_barcode,
              locn_name: 'Shelf 1',
              locn_parentage: locn_prefix
            )
            stub_lwclient_locn_children(location_barcode, [])
            stub_lwclient_locn_labwares(location_barcode, [p1])
            stub_lwclient_labware_find_by_bc(p1)

            plate_1_custom_metadatum
          end

          it_behaves_like 'a successful report'
        end

        describe 'when multiple labwares in same sub-location' do
          let(:location_barcode) { 'locn-1-at-lvl-1' }
          let(:plt_1_line) do
            # rubocop:todo Layout/LineLength
            "#{plate_1.machine_barcode},#{plate_1.human_barcode},#{plt_1_purpose},#{plt_1_created},#{plt_1_received_date},#{locn_prefix} - Shelf 1 - Box 1,LabWhere,#{retention_value},#{study_1.name},#{study_1.id},#{study_1_sponsor.name}"
            # rubocop:enable Layout/LineLength
          end
          let(:plt_2_line_1) do
            # rubocop:todo Layout/LineLength
            "#{plate_2.machine_barcode},#{plate_2.human_barcode},#{plt_2_purpose},#{plt_2_created},#{plt_2_received_date},#{locn_prefix} - Shelf 1 - Box 1,LabWhere,Unknown,#{study_1.name},#{study_1.id},#{study_1_sponsor.name}"
            # rubocop:enable Layout/LineLength
          end
          let(:plt_2_line_2) do
            # rubocop:todo Layout/LineLength
            "#{plate_2.machine_barcode},#{plate_2.human_barcode},#{plt_2_purpose},#{plt_2_created},#{plt_2_received_date},#{locn_prefix} - Shelf 1 - Box 1,LabWhere,Unknown,#{study_2.name},#{study_2.id},#{study_2_sponsor.name}"
            # rubocop:enable Layout/LineLength
          end
          let(:expected_lines) { [headers_line, plt_1_line, plt_2_line_1, plt_2_line_2] }

          before do
            # set up Shelf 1 with no labwares and 1 sub-location
            stub_lwclient_locn_find_by_bc(
              locn_barcode: location_barcode,
              locn_name: 'Shelf 1',
              locn_parentage: locn_prefix
            )
            stub_lwclient_locn_children(
              location_barcode,
              [{ locn_barcode: 'locn-1-at-lvl-2', locn_name: 'Box 1', locn_parentage: "#{locn_prefix} - Shelf 1" }]
            )
            stub_lwclient_locn_labwares(location_barcode, [])

            # set up Shelf 1 - Box 1 with 2 labwares and no sub-locations
            p1 = {
              lw_barcode: plate_1.machine_barcode,
              lw_locn_name: 'Box 1',
              lw_locn_parentage: "#{locn_prefix} - Shelf 1"
            }
            p2 = {
              lw_barcode: plate_2.machine_barcode,
              lw_locn_name: 'Box 1',
              lw_locn_parentage: "#{locn_prefix} - Shelf 1"
            }
            stub_lwclient_locn_find_by_bc(
              locn_barcode: 'locn-1-at-lvl-2',
              locn_name: 'Box 1',
              locn_parentage: "#{locn_prefix} - Shelf 1"
            )
            stub_lwclient_locn_children(location_barcode, [])
            stub_lwclient_locn_labwares(location_barcode, [p1, p2])
            stub_lwclient_labware_find_by_bc(p1)
            stub_lwclient_labware_find_by_bc(p2)

            plate_1_custom_metadatum
          end

          it_behaves_like 'a successful report'
        end

        describe 'when multiple labwares in different sub-locations' do
          let(:location_barcode) { 'locn-1-at-lvl-1' }
          let(:plt_1_line) do
            # rubocop:todo Layout/LineLength
            "#{plate_1.machine_barcode},#{plate_1.human_barcode},#{plt_1_purpose},#{plt_1_created},#{plt_1_received_date},#{locn_prefix} - Shelf 1 - Box 1,LabWhere,#{retention_value},#{study_1.name},#{study_1.id},#{study_1_sponsor.name}"
            # rubocop:enable Layout/LineLength
          end
          let(:plt_2_line_1) do
            # rubocop:todo Layout/LineLength
            "#{plate_2.machine_barcode},#{plate_2.human_barcode},#{plt_2_purpose},#{plt_2_created},#{plt_2_received_date},#{locn_prefix} - Shelf 1 - Box 2,LabWhere,Unknown,#{study_1.name},#{study_1.id},#{study_1_sponsor.name}"
            # rubocop:enable Layout/LineLength
          end
          let(:plt_2_line_2) do
            # rubocop:todo Layout/LineLength
            "#{plate_2.machine_barcode},#{plate_2.human_barcode},#{plt_2_purpose},#{plt_2_created},#{plt_2_received_date},#{locn_prefix} - Shelf 1 - Box 2,LabWhere,Unknown,#{study_2.name},#{study_2.id},#{study_2_sponsor.name}"
            # rubocop:enable Layout/LineLength
          end
          let(:expected_lines) { [headers_line, plt_1_line, plt_2_line_1, plt_2_line_2] }

          before do
            # set up Shelf 1 with no labwares and two sub-locations
            locn_lvl2_b1 = {
              locn_barcode: 'locn-1a-at-lvl-2',
              locn_name: 'Box 1',
              locn_parentage: "#{locn_prefix} - Shelf 1"
            }
            locn_lvl2_b2 = {
              locn_barcode: 'locn-1b-at-lvl-2',
              locn_name: 'Box 2',
              locn_parentage: "#{locn_prefix} - Shelf 1"
            }
            stub_lwclient_locn_find_by_bc(
              locn_barcode: location_barcode,
              locn_name: 'Shelf 1',
              locn_parentage: locn_prefix
            )
            stub_lwclient_locn_children(location_barcode, [locn_lvl2_b1, locn_lvl2_b2])
            stub_lwclient_locn_labwares(location_barcode, [])

            # set up Shelf 1 - Box 1 with one labware and no sub-locations
            p1 = {
              lw_barcode: plate_1.machine_barcode,
              lw_locn_name: 'Box 1',
              lw_locn_parentage: "#{locn_prefix} - Shelf 1"
            }
            stub_lwclient_locn_find_by_bc(locn_lvl2_b1)
            stub_lwclient_locn_children(locn_lvl2_b1[:locn_barcode], [])
            stub_lwclient_locn_labwares(locn_lvl2_b1[:locn_barcode], [p1])
            stub_lwclient_labware_find_by_bc(p1)

            # set up Shelf 1 - Box 2 with one labware and no sub-locations
            p2 = {
              lw_barcode: plate_2.machine_barcode,
              lw_locn_name: 'Box 2',
              lw_locn_parentage: "#{locn_prefix} - Shelf 1"
            }
            stub_lwclient_locn_find_by_bc(locn_lvl2_b2)
            stub_lwclient_locn_children(locn_lvl2_b2[:locn_barcode], [])
            stub_lwclient_locn_labwares(locn_lvl2_b2[:locn_barcode], [p2])
            stub_lwclient_labware_find_by_bc(p2)

            plate_1_custom_metadatum
            # plate_3_custom_metadatum
          end

          it_behaves_like 'a successful report'
        end

        describe 'when multiple labwares at different levels' do
          let(:location_barcode) { 'locn-1-at-lvl-1' }

          # rubocop:todo Layout/LineLength
          let(:plt_1_line) do
            "#{plate_1.machine_barcode},#{plate_1.human_barcode},#{plt_1_purpose},#{plt_1_created},#{plt_1_received_date},#{locn_prefix} - Shelf 1,LabWhere,#{retention_value},#{study_1.name},#{study_1.id},#{study_1_sponsor.name}"
          end
          let(:plt_2_line_1) do
            "#{plate_2.machine_barcode},#{plate_2.human_barcode},#{plt_2_purpose},#{plt_2_created},#{plt_2_received_date},#{locn_prefix} - Shelf 1 - Tray 1,LabWhere,Unknown,#{study_1.name},#{study_1.id},#{study_1_sponsor.name}"
          end
          let(:plt_2_line_2) do
            "#{plate_2.machine_barcode},#{plate_2.human_barcode},#{plt_2_purpose},#{plt_2_created},#{plt_2_received_date},#{locn_prefix} - Shelf 1 - Tray 1,LabWhere,Unknown,#{study_2.name},#{study_2.id},#{study_2_sponsor.name}"
          end
          let(:plt_3_line) do
            "#{plate_3.machine_barcode},#{plate_3.human_barcode},#{plt_3_purpose},#{plt_3_created},#{plt_3_received_date},#{locn_prefix} - Shelf 1 - Tray 1 - Box 1,LabWhere,#{retention_value},#{study_2.name},#{study_2.id},#{study_2_sponsor.name}"
          end

          # rubocop:enable Layout/LineLength

          let(:expected_lines) { [headers_line, plt_1_line, plt_2_line_1, plt_2_line_2, plt_3_line] }

          before do
            # set up Shelf 1 with 1 labware and 1 sub-location
            locn_lvl2_t1 = {
              locn_barcode: 'locn-1-at-lvl-2',
              locn_name: 'Tray 1',
              locn_parentage: "#{locn_prefix} - Shelf 1"
            }
            p1 = { lw_barcode: plate_1.machine_barcode, lw_locn_name: 'Shelf 1', lw_locn_parentage: locn_prefix }
            stub_lwclient_locn_find_by_bc(
              locn_barcode: location_barcode,
              locn_name: 'Shelf 1',
              locn_parentage: locn_prefix
            )
            stub_lwclient_locn_children(location_barcode, [locn_lvl2_t1])
            stub_lwclient_locn_labwares(location_barcode, [p1])
            stub_lwclient_labware_find_by_bc(p1)

            # set up Shelf 1 - Tray 1 with 1 labware and 1 sub-location
            locn_lvl3_b1 = {
              locn_barcode: 'locn-1-at-lvl-3',
              locn_name: 'Box 1',
              locn_parentage: "#{locn_prefix} - Shelf 1 - Tray 1"
            }
            p2 = {
              lw_barcode: plate_2.machine_barcode,
              lw_locn_name: 'Tray 1',
              lw_locn_parentage: "#{locn_prefix} - Shelf 1"
            }
            stub_lwclient_locn_find_by_bc(locn_lvl2_t1)
            stub_lwclient_locn_children(locn_lvl2_t1[:locn_barcode], [locn_lvl3_b1])
            stub_lwclient_locn_labwares(locn_lvl2_t1[:locn_barcode], [p2])
            stub_lwclient_labware_find_by_bc(p2)

            # set up Shelf 1 - Tray 1 - Box 1 with 1 labware and no sub-locations
            p3 = {
              lw_barcode: plate_3.machine_barcode,
              lw_locn_name: 'Box 1',
              lw_locn_parentage: "#{locn_prefix} - Shelf 1 - Tray 1"
            }
            stub_lwclient_locn_find_by_bc(locn_lvl3_b1)
            stub_lwclient_locn_children(locn_lvl3_b1[:locn_barcode], [])
            stub_lwclient_locn_labwares(locn_lvl3_b1[:locn_barcode], [p3])
            stub_lwclient_labware_find_by_bc(p3)

            plate_1_custom_metadatum
            plate_3_custom_metadatum
          end

          it_behaves_like 'a successful report'
        end
      end
    end
  end
end
