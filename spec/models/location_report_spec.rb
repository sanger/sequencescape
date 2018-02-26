# frozen_string_literal: true

# This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2018 Genome Research Ltd.

require 'rails_helper'

RSpec.describe LocationReport, type: :model do
  let(:studies) do
    create_list(:study, 2)
  end

  let(:study_1)               { studies[0] }
  let(:study_2)               { studies[1] }

  let(:study_1_name)          { study_1.name }
  let(:study_1_sponsor)       { study_1.study_metadata.faculty_sponsor.name }

  let(:study_2_name)          { study_2.name }
  let(:study_2_sponsor)       { study_2.study_metadata.faculty_sponsor.name }

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

  let(:headers_line)          { 'Barcode,HumanBarcode,Type,Created,Location,Service,Study,Owner' }
  let(:locn_prefix)           { 'Sanger - Ogilvie - AA209 - Freezer 1' }

  context 'when checking basic model functionality' do
    let(:location_report) { create :location_report_barcodes, barcodes_text: '1234567890123' }

    it 'is not valid without a report name' do
      expect(location_report.name).to be_present
    end

    it 'is not valid unless the name has a specific format' do
      expect(location_report.name).to match(/[0-9]{14}/)
    end

    it 'is not valid without a report type' do
      expect(build(:location_report, report_type: nil)).to_not be_valid
    end
  end

  context 'when testing report generation' do
    let(:location_report) do
      build(
        :location_report,
        report_type: report_type,
        barcodes_text: barcodes_text,
        study_id: study_id,
        start_date: start_date,
        end_date: end_date,
        plate_purpose_ids: plate_purpose_ids
      )
    end
    let(:report_type) { nil }
    let(:barcodes_text) { nil }
    let(:study_id) { nil }
    let(:start_date) { nil }
    let(:end_date) { nil }
    let(:plate_purpose_ids) { nil }

    context 'when checking report type selection validations' do
      let(:report_type) { 'selection' }

      it 'is not valid if there is no start date' do
        location_report.end_date = '2016-07-01 00:00:00'
        expect(location_report).to_not be_valid
      end

      it 'is not valid if there is no end date' do
        location_report.start_date = '2016-06-01 00:00:00'
        expect(location_report).to_not be_valid
      end
    end

    context 'when checking report type barcodes validations' do
      let(:report_type) { 'barcodes' }

      it 'is not valid if there are no barcodes in the list' do
        location_report.barcodes_text = nil
        expect(location_report.valid?).to be_falsey
      end

      it 'is not valid if the barcodes list only contains whitespace' do
        location_report.barcodes_text = '       '
        expect(location_report.valid?).to be_falsey
      end

      it 'is valid to have multiple barcodes in the text field with variable spacing' do
        location_report.barcodes_text = ' 1234567890101 1234567890102     1234567890103          1234567890104 '
        expect(location_report.valid?).to be_truthy
      end

      it 'correctly isolates the barcodes from a list with variable spacing' do
        location_report.barcodes_text = ' 1234567890101 1234567890102     1234567890103          1234567890104 '
        expect(location_report.barcodes_list.size).to eq(4)
      end
    end

    context 'when checking report generation' do
      let(:plt_1_line) { "#{plate_1.machine_barcode},#{plate_1.sanger_human_barcode},#{plt_1_purpose},#{plt_1_created},#{locn_prefix} - Shelf 1,LabWhere,#{study_1_name},#{study_1_sponsor}" }
      let(:plt_2_line_1) { "#{plate_2.machine_barcode},#{plate_2.sanger_human_barcode},#{plt_2_purpose},#{plt_2_created},#{locn_prefix} - Shelf 2,LabWhere,#{study_1_name},#{study_1_sponsor}" }
      let(:plt_2_line_2) { "#{plate_2.machine_barcode},#{plate_2.sanger_human_barcode},#{plt_2_purpose},#{plt_2_created},#{locn_prefix} - Shelf 2,LabWhere,#{study_2_name},#{study_2_sponsor}" }
      let(:plt_3_line) { "#{plate_3.machine_barcode},#{plate_3.sanger_human_barcode},#{plt_3_purpose},#{plt_3_created},#{locn_prefix} - Shelf 3,LabWhere,#{study_2_name},#{study_2_sponsor}" }

      before(:each) do
        plate_1
        plate_2
        plate_3

        allow(LabWhereClient::Labware).to receive(:find_by_barcode)
          .with(plate_1.ean13_barcode.to_s)
          .and_return(
            LabWhereClient::Labware.new(
              'barcode' => plate_1.ean13_barcode,
              'location' => {
                'name' => 'Shelf 1',
                'parentage' => locn_prefix
              }
            )
          )

        allow(LabWhereClient::Labware).to receive(:find_by_barcode)
          .with(plate_2.ean13_barcode.to_s)
          .and_return(
            LabWhereClient::Labware.new(
              'barcode' => plate_2.ean13_barcode,
              'location' => {
                'name' => 'Shelf 2',
                'parentage' => locn_prefix
              }
            )
          )

        allow(LabWhereClient::Labware).to receive(:find_by_barcode)
          .with(plate_3.ean13_barcode.to_s)
          .and_return(
            LabWhereClient::Labware.new(
              'barcode' => plate_3.ean13_barcode,
              'location' => {
                'name' => 'Shelf 3',
                'parentage' => locn_prefix
              }
            )
          )
      end

      shared_context 'a successful report' do
        it 'generates the expected report rows' do
          location_report.save

          lines = []
          location_report.generate_report_rows do |fields|
            lines.push(fields.join(','))
          end

          expect(lines).to eq(expected_lines)
        end
      end

      context 'where plates are identified by selection' do
        let(:report_type) { 'selection' }

        context 'when selecting by dates only' do
          let(:start_date) { '2016-01-01 00:00:00' }
          let(:end_date) { '2016-07-01 00:00:00' }
          let(:expected_lines) { [headers_line, plt_1_line, plt_2_line_1, plt_2_line_2] }

          it_behaves_like 'a successful report'
        end

        context 'when selecting by dates and study' do
          let(:study_id) { study_1.id }
          let(:start_date) { '2016-01-01 00:00:00' }
          let(:end_date) { '2016-05-01 00:00:00' }
          let(:expected_lines) { [headers_line, plt_1_line] }

          it_behaves_like 'a successful report'
        end

        context 'when selecting by dates and plate purpose' do
          let(:start_date) { '2016-01-01 00:00:00' }
          let(:end_date) { '2016-11-01 00:00:00' }
          let(:plate_purpose_ids) { [plate_1.plate_purpose.id] }
          let(:expected_lines) { [headers_line, plt_1_line] }

          it_behaves_like 'a successful report'
        end

        context 'when selecting by dates and plate purpose for a mixed study plate' do
          let(:start_date) { '2016-01-01 00:00:00' }
          let(:end_date) { '2016-07-01 00:00:00' }
          let(:plate_purpose_ids) { [plate_2.plate_purpose.id] }
          let(:expected_lines) { [headers_line, plt_2_line_1, plt_2_line_2] }

          it_behaves_like 'a successful report'
        end

        context 'when selecting by dates and multiple plate purposes' do
          let(:start_date) { '2016-01-01 00:00:00' }
          let(:end_date) { '2016-11-01 00:00:00' }
          let(:plate_purpose_ids) { [plate_2.plate_purpose.id, plate_3.plate_purpose.id] }
          let(:expected_lines) { [headers_line, plt_2_line_1, plt_2_line_2, plt_3_line] }

          it_behaves_like 'a successful report'
        end

        context 'when selecting by dates, study and plate purpose' do
          let(:study_id) { study_2.id }
          let(:start_date) { '2016-01-01 00:00:00' }
          let(:end_date) { '2016-11-01 00:00:00' }
          let(:plate_purpose_ids) { [plate_3.plate_purpose.id] }
          let(:expected_lines) { [headers_line, plt_3_line] }

          it_behaves_like 'a successful report'
        end

        context 'when selecting by dates, the first study and a plate purpose for a mixed study plate' do
          let(:study_id) { study_1.id }
          let(:start_date) { '2016-01-01 00:00:00' }
          let(:end_date) { '2016-11-01 00:00:00' }
          let(:plate_purpose_ids) { [plate_2.plate_purpose.id] }
          let(:expected_lines) { [headers_line, plt_2_line_1, plt_2_line_2] }

          it_behaves_like 'a successful report'
        end

        context 'when selecting by dates, the second study and a plate purpose for a mixed study plate' do
          let(:study_id) { study_2.id }
          let(:start_date) { '2016-01-01 00:00:00' }
          let(:end_date) { '2016-11-01 00:00:00' }
          let(:plate_purpose_ids) { [plate_2.plate_purpose.id] }
          let(:expected_lines) { [headers_line, plt_2_line_1, plt_2_line_2] }

          it_behaves_like 'a successful report'
        end
      end

      context 'where plates are selected by a list of barcodes' do
        let(:report_type) { 'barcodes' }

        context 'when for a single-study plate' do
          let(:barcodes_text) { plate_1.machine_barcode.to_s }
          let(:expected_lines) { [headers_line, plt_1_line] }

          it_behaves_like 'a successful report'
        end

        context 'when for a mixed study plate' do
          let(:barcodes_text) { plate_2.machine_barcode.to_s }
          let(:expected_lines) { [headers_line, plt_2_line_1, plt_2_line_2] }

          it_behaves_like 'a successful report'
        end

        context 'when for multiple plates' do
          let(:barcodes_text) { "#{plate_1.machine_barcode} #{plate_2.machine_barcode} #{plate_3.machine_barcode}" }
          let(:expected_lines) { [headers_line, plt_1_line, plt_2_line_1, plt_2_line_2, plt_3_line] }

          it_behaves_like 'a successful report'
        end

        context 'when using human readable barcodes' do
          let(:barcodes_text) { "#{plate_1.sanger_human_barcode} #{plate_3.sanger_human_barcode}" }
          let(:expected_lines) { [headers_line, plt_1_line, plt_3_line] }

          it_behaves_like 'a successful report'
        end

        context 'when a barcode is unrecognised' do
          let(:barcodes_text) { "#{plate_1.machine_barcode} 9999999999999" }
          let(:expected_lines) { [headers_line, plt_1_line] }

          it_behaves_like 'a successful report'
        end
      end
    end
  end
end
