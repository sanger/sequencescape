# frozen_string_literal: true

# This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2018 Genome Research Ltd.

require 'rails_helper'

RSpec.describe LocationReport::FormObject, type: :model do
  let(:studies) do
    create_list(:study, 2)
  end

  let(:study_1)               { studies[0] }
  let(:study_2)               { studies[1] }

  let(:study_1_sponsor)       { study_1.study_metadata.faculty_sponsor }
  let(:study_2_sponsor)       { study_2.study_metadata.faculty_sponsor }

  let!(:plate_1) do
    create(
      :plate_with_wells_for_specified_studies,
      studies: [study_1],
      name: 'Plate_1',
      created_at: '2016-02-01 00:00:00'
    )
  end

  let(:plt_1_purpose)         { plate_1.plate_purpose }
  let(:plt_1_created)         { plate_1.created_at.strftime('%Y-%m-%d %H:%M:%S') }

  let!(:plate_2) do
    create(
      :plate_with_wells_for_specified_studies,
      studies: [study_1, study_2],
      name: 'Plate_2',
      created_at: '2016-06-01 00:00:00'
    )
  end

  let(:plt_2_purpose)         { plate_2.plate_purpose }
  let(:plt_2_created)         { plate_2.created_at.strftime('%Y-%m-%d %H:%M:%S') }

  let!(:plate_3) do
    create(
      :plate_with_wells_for_specified_studies,
      studies: [study_2],
      name: 'Plate_3',
      created_at: '2016-10-01 00:00:00'
    )
  end

  let(:plt_3_purpose)         { plate_3.plate_purpose }
  let(:plt_3_created)         { plate_3.created_at.strftime('%Y-%m-%d %H:%M:%S') }

  let(:headers_line)          { 'ScannedBarcode,HumanBarcode,Type,Created,Location,Service,StudyName,StudyId,FacultySponsor' }
  let(:locn_prefix)           { 'Sanger - Ogilvie - AA209 - Freezer 1' }

  context 'when checking validations' do
    let(:location_report_form_object) do
      build(
        :location_report_form_object,
        report_type: report_type,
        name: name,
        location_barcode: location_barcode,
        faculty_sponsor_ids: faculty_sponsor_ids,
        study_id: study_id,
        start_date: start_date,
        end_date: end_date,
        plate_purpose_ids: plate_purpose_ids,
        barcodes_text: barcodes_text
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
    let(:barcodes_text) { nil }

    context 'when a name is not supplied' do
      let(:report_type) { 'type_selection' }
      let(:start_date) { '2016-01-01 00:00:00' }
      let(:end_date) { '2016-07-01 00:00:00' }

      before(:each) do
        location_report_form_object.valid?
      end

      it 'a report name should be generated' do
        expect(location_report_form_object.name).to be_present
      end

      it 'the report name has a timestamp format' do
        location_report_form_object.valid?
        expect(location_report_form_object.name).to match(/[0-9]{14}/)
      end
    end

    context 'when entered name is only spaces' do
      let(:name) { '          ' }
      let(:report_type) { 'type_selection' }
      let(:start_date) { '2016-01-01 00:00:00' }
      let(:end_date) { '2016-07-01 00:00:00' }

      it 'the model is valid' do
        expect(location_report_form_object).to be_valid
      end

      it 'the report name has a timestamp format' do
        location_report_form_object.valid?
        expect(location_report_form_object.name).to match(/[0-9]{14}/)
      end
    end

    context 'when a name is supplied' do
      let(:report_type) { 'type_selection' }
      let(:name) { 'Test name' }
      let(:start_date) { '2016-01-01 00:00:00' }
      let(:end_date) { '2016-07-01 00:00:00' }

      it 'is used instead of auto-generating one' do
        location_report_form_object.valid?
        expect(location_report_form_object.name).to eq('Test_name')
      end
    end

    context 'when nothing is selected' do
      let(:report_type) { 'type_selection' }

      it 'is not valid' do
        expect(location_report_form_object).to_not be_valid
      end
    end

    context 'when selecting using dates' do
      let(:report_type) { 'type_selection' }

      it 'is not valid if there is an end date but no start date' do
        location_report_form_object.end_date = '2016-07-01 00:00:00'
        expect(location_report_form_object).to_not be_valid
      end

      it 'is not valid if there is a start date but no end date' do
        location_report_form_object.start_date = '2016-06-01 00:00:00'
        expect(location_report_form_object).to_not be_valid
      end

      it 'is not valid if the start date is after the end date' do
        location_report_form_object.start_date = '2016-08-01 00:00:00'
        location_report_form_object.end_date = '2016-07-01 00:00:00'
        expect(location_report_form_object).to_not be_valid
      end

      it 'is is valid for the start date to be the same as the end date' do
        location_report_form_object.start_date = '2016-06-01 00:00:00'
        location_report_form_object.end_date = '2016-06-01 00:00:00'
        expect(location_report_form_object).to_not be_valid
      end

      it 'is not valid if the dates do not find any plates' do
        location_report_form_object.start_date = '2016-07-01 00:00:00'
        location_report_form_object.end_date = '2016-07-02 00:00:00'
        expect(location_report_form_object).to_not be_valid
      end
    end

    context 'when selecting using barcodes' do
      let(:report_type) { 'type_selection' }

      it 'is not valid if the barcodes list only contains whitespace' do
        location_report_form_object.barcodes_text = '       '
        expect(location_report_form_object).to_not be_valid
      end

      it 'is not valid if there is a poorly formatted barcode in the list' do
        location_report_form_object.barcodes_text = "#{plate_1.machine_barcode} INVALID123 #{plate_2.sanger_human_barcode}"
        expect(location_report_form_object).to_not be_valid
      end

      it 'is valid to use human readable barcodes' do
        location_report_form_object.barcodes_text = plate_1.sanger_human_barcode.to_s
        expect(location_report_form_object).to be_valid
      end

      it 'is valid to use human readable barcodes missing the final check digit character' do
        location_report_form_object.barcodes_text = plate_1.sanger_human_barcode.to_s[0...-1]
        expect(location_report_form_object).to be_valid
      end

      it 'is valid to enter barcodes with commas separating them' do
        location_report_form_object.barcodes_text = "#{plate_1.machine_barcode},#{plate_2.machine_barcode},#{plate_3.machine_barcode}"
        expect(location_report_form_object).to be_valid
      end

      it 'is valid to enter barcodes with commas and spaces separating them' do
        location_report_form_object.barcodes_text = "#{plate_1.machine_barcode},   #{plate_2.machine_barcode}   ,  #{plate_3.machine_barcode}"
        expect(location_report_form_object).to be_valid
      end

      context 'when barcodes are input with varied spacing or spaces at the beginning or end' do
        before(:each) do
          location_report_form_object.barcodes_text = " #{plate_1.machine_barcode} #{plate_2.sanger_human_barcode}     #{plate_3.machine_barcode}        "
        end

        it 'the model is valid' do
          expect(location_report_form_object).to be_valid
        end

        it 'correctly isolates the right number of barcodes' do
          location_report_form_object.valid?
          expect(location_report_form_object.barcodes&.size).to eq(3)
        end
      end
    end

    context 'when using multiple barcodes and criteria that result in no plates found' do
      let(:report_type) { 'type_selection' }
      let(:barcodes) { [plate_1.machine_barcode, plate_2.machine_barcode, plate_3.machine_barcode] }
      let(:start_date) { '2016-11-15 00:00:00' }
      let(:end_date) { '2016-11-17 00:00:00' }

      it 'the model is not valid' do
        expect(location_report_form_object).to_not be_valid
      end
    end

    context 'when a valid selection form object model is saved' do
      let(:name) { 'Test name' }
      let(:report_type) { 'type_selection' }
      let(:faculty_sponsor_ids) { [study_1_sponsor.id] }
      let(:study_id) { study_1.id }
      let(:start_date) { '2016-01-01 00:00:00' }
      let(:end_date) { '2016-03-01 00:00:00' }
      let(:plate_purpose_ids) { [plt_1_purpose.id] }
      let(:barcodes_text) { plate_1.machine_barcode.to_s }

      before(:each) do
        location_report_form_object.save
      end

      it 'creates a location report' do
        expect(location_report_form_object.location_report).to be_present
      end

      it 'creates a valid location report' do
        expect(location_report_form_object.location_report).to be_valid
      end

      it 'correctly records the form object information in the location report' do
        expect(location_report_form_object.location_report.name).to eq('Test_name')
        expect(location_report_form_object.location_report.report_type).to eq('type_selection')
        expect(location_report_form_object.location_report.faculty_sponsor_ids).to eq([study_1_sponsor.id])
        expect(location_report_form_object.location_report.study_id).to eq(study_1.id)
        expect(location_report_form_object.location_report.start_date.strftime('%Y-%m-%d %H:%M:%S')).to eq('2016-01-01 00:00:00')
        expect(location_report_form_object.location_report.end_date.strftime('%Y-%m-%d %H:%M:%S')).to eq('2016-03-01 00:00:00')
        expect(location_report_form_object.location_report.plate_purpose_ids).to eq([plt_1_purpose.id])
        expect(location_report_form_object.location_report.barcodes).to eq([plate_1.machine_barcode.to_s])
      end
    end

    context 'when a labwhere location is supplied' do
      let(:report_type) { 'type_labwhere' }
      let(:locn_prefix) { 'Sanger - Ogilvie - AA209 - Freezer 1' }

      before(:each) do
        allow(LabWhereClient::Location).to receive(:find_by_barcode)
          .with('1001')
          .and_return(
            LabWhereClient::Location.new(
              'name' => 'Shelf 1',
              'parentage' => locn_prefix
            )
          )

        allow(LabWhereClient::Location).to receive(:find_by_barcode)
          .with('9999')
          .and_return(nil)
      end

      context 'for a valid location' do
        let(:location_barcode) { '1001' }

        it 'the model is valid' do
          expect(location_report_form_object).to be_valid
        end
      end

      context 'for an invalid location' do
        let(:location_barcode) { '9999' }

        it 'the model is not valid' do
          expect(location_report_form_object).to_not be_valid
        end
      end
    end

    context 'when a valid labwhere form object model is saved' do
      let(:name) { 'Test name' }
      let(:report_type) { 'type_labwhere' }
      let(:location_barcode) { '1001' }

      before(:each) do
        allow(LabWhereClient::Location).to receive(:find_by_barcode)
          .with('1001')
          .and_return(
            LabWhereClient::Location.new(
              'name' => 'Shelf 1',
              'parentage' => locn_prefix
            )
          )

        location_report_form_object.save
      end

      it 'creates a location report' do
        expect(location_report_form_object.location_report).to be_present
      end

      it 'creates a valid location report' do
        expect(location_report_form_object.location_report).to be_valid
      end

      it 'correctly records the form object information in the location report' do
        expect(location_report_form_object.location_report.name).to eq('Test_name')
        expect(location_report_form_object.location_report.report_type).to eq('type_labwhere')
        expect(location_report_form_object.location_report.location_barcode).to eq('1001')
      end
    end
  end
end
