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

  let(:plt_1_purpose)         { plate_1.plate_purpose.name }
  let(:plt_1_created)         { plate_1.created_at.strftime('%Y-%m-%d %H:%M:%S') }

  let!(:plate_2) do
    create(
      :plate_with_wells_for_specified_studies,
      studies: [study_1, study_2],
      name: 'Plate_2',
      created_at: '2016-06-01 00:00:00'
    )
  end

  let(:plt_2_purpose)         { plate_2.plate_purpose.name }
  let(:plt_2_created)         { plate_2.created_at.strftime('%Y-%m-%d %H:%M:%S') }

  let!(:plate_3) do
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

  context 'when checking validations' do
    let(:location_report_form_object) do
      build(
        :location_report_form_object,
        report_type: report_type,
        name: name,
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
        expect(location_report_form_object.valid?).to be_falsey
      end

      it 'is not valid if there is a poorly formatted barcode in the list' do
        location_report_form_object.barcodes_text = "plate_1.machine_barcode.to_s INVALID123 plate_1.sanger_human_barcode.to_s"
        expect(location_report_form_object.valid?).to be_falsey
      end

      it 'is valid to use human readable barcodes' do
        location_report_form_object.barcodes_text = plate_1.sanger_human_barcode.to_s
        expect(location_report_form_object.valid?).to be_truthy
      end

      # it 'is valid to use human readable barcodes missing the check digit character' do
      #   location_report_form_object.barcodes_text = 'DN1'
      #   expect(location_report_form_object.valid?).to be_truthy
      # end

      # it 'is valid to have multiple barcodes in the text field with variable spacing' do
      #   location_report_form_object.barcodes_text = ' 1234567890101 DN1S     1234567890103          DN2 '
      #   expect(location_report_form_object.valid?).to be_truthy
      # end

      # it 'correctly isolates the barcodes from a list with variable spacing' do
      #   location_report_form_object.barcodes_text = ' 1234567890101 1234567890102     1234567890103          1234567890104 '
      #   expect(location_report_form_object.barcodes.size).to eq(4)
      # end
    end

    # context 'when valid barcodes are entered' do
    #   it 'the model is valid' do
    #     expect(location_report_form_object_form_object).to be_valid
    #   end
    # end

    # context 'when an invalid barcode is entered with valid barcodes' do
    #   it 'the model is invalid' do
    #     location_report_form_object_form_object.barcodes_text = 'ACGTACGT INVALID ACTGCATG'
    #     expect(location_report_form_object_form_object).to_not be_valid
    #   end
    # end

    # context 'when only invalid barcodes are entered' do
    #   it 'the model is invalid' do
    #     location_report_form_object_form_object.barcodes_text = 'INVALID1 INVALID2 INVALID3'
    #     expect(location_report_form_object_form_object).to_not be_valid
    #   end
    # end

    # context 'when a duplicate barcode is entered' do
    #   it 'the model is invalid' do
    #     location_report_form_object_form_object.barcodes_text = 'ACGTACGT ACTGCATG ACTGCATG'
    #     expect(location_report_form_object_form_object).to_not be_valid
    #   end
    # end

    # context 'when barcodes are separated by multiple spaces' do
    #   before(:each) do
    #     location_report_form_object_form_object.barcodes_text = ' ACGTACGT    ACTGCATG  ACTGGGCC   '
    #   end

    #   it 'the model is valid' do
    #     expect(location_report_form_object_form_object).to be_valid
    #   end
    # end

    # context 'when no barcodes are entered' do
    #   it 'the model is invalid' do
    #     location_report_form_object_form_object.barcodes_text = '        '
    #     expect(location_report_form_object_form_object).to_not be_valid
    #   end
    # end

    # context 'when no name is entered' do
    #   it 'the model is invalid' do
    #     location_report_form_object_form_object.name = nil
    #     expect(location_report_form_object_form_object).to_not be_valid
    #   end
    # end

    # context 'when entered name is only spaces' do
    #   it 'the model is invalid' do
    #     location_report_form_object_form_object.name = '      '
    #     expect(location_report_form_object_form_object).to_not be_valid
    #   end
    # end

    # context 'when a valid model is saved' do
    #   before(:each) do
    #     location_report_form_object_form_object.save
    #   end

    #   it 'creates a valid location report' do
    #     expect(location_report_form_object_form_object.location_report_form_object).to be_valid
    #   end
    # end

    # context 'when the barcodes are entered with commas separating them' do
    #   before(:each) do
    #     location_report_form_object_form_object.barcodes_text = 'ACCTTGGA,GGTTACAC,TAATCGCA'
    #   end

    #   it 'the model is valid' do
    #     expect(location_report_form_object_form_object).to be_valid
    #   end
    # end

    # context 'when the barcodes are entered with commas and spaces separating them' do
    #   before(:each) do
    #     location_report_form_object_form_object.barcodes_text = 'ACCTTGGA, GGTTACAC,  TAATCGCA'
    #   end

    #   it 'the model is valid' do
    #     expect(location_report_form_object_form_object).to be_valid
    #   end
    # end
  end
end