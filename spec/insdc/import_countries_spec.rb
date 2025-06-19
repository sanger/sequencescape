# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Insdc::ImportCountries do
  subject(:importer) { described_class.new(ena_root:, sample_checklist:, priorities:) }

  before do
    # The File api is used heavily internally, and we're going to be mocking it a
    # bit here, so first thing is to set the default implementation to the original
    # so we don't get in the way of things like RSpec itself or pry.
    allow(File).to receive(:exist?).and_call_original
    allow(File).to receive(:open).and_call_original
  end

  let(:ena_root) { 'http://www.example.com/' }
  let(:sample_checklist) { 'example' }
  let(:data_dir) { Insdc::ImportCountries::FILE_ROOT }
  let(:cached_file_path) { "#{data_dir}/#{sample_checklist}.xml" }
  let(:priorities) { { 'not applicable' => 1 } }
  let(:mock_response) { <<~XML }
    <?xml version="1.0" encoding="UTF-8"?>
    <CHECKLIST_SET>
        <CHECKLIST accession="example" checklistType="Sample">
              <IDENTIFIERS>
                  <PRIMARY_ID>example</PRIMARY_ID>
              </IDENTIFIERS>
              <DESCRIPTOR>
                  <LABEL>Label</LABEL>
                  <NAME>Name</NAME>
                  <DESCRIPTION>Description</DESCRIPTION>
                  <AUTHORITY>Authority</AUTHORITY>
                  <FIELD_GROUP restrictionType="Any number or none of the fields">
                        <NAME>Collection event information</NAME>
                        <FIELD>
                            <LABEL>collection_date</LABEL>
                            <NAME>collection_date</NAME>
                            <DESCRIPTION>date that the specimen was collected</DESCRIPTION>
                            <FIELD_TYPE>
                                  <TEXT_FIELD>
                                      <REGEX_VALUE>(^[12][0-9]{3}(-(0[1-9]|1[0-2])(-(0[1-9]|[12][0-9]|3[01])(T[0-9]{2}:[0-9]{2}(:[0-9]{2})?Z?([+-][0-9]{1,2})?)?)?)?(/[0-9]{4}(-[0-9]{2}(-[0-9]{2}(T[0-9]{2}:[0-9]{2}(:[0-9]{2})?Z?([+-][0-9]{1,2})?)?)?)?)?$)|(^not collected$)|(^not provided$)|(^restricted access$)</REGEX_VALUE>
                                  </TEXT_FIELD>
                            </FIELD_TYPE>
                            <MANDATORY>optional</MANDATORY>
                            <MULTIPLICITY>multiple</MULTIPLICITY>
                        </FIELD>
                        <FIELD>
                            <LABEL>geographic location (country and/or sea)</LABEL>
                            <NAME>geographic location (country and/or sea)</NAME>
                            <DESCRIPTION>The geographical origin of the sample as defined by the country or sea. Country or sea names should be chosen from the INSDC country list (http://insdc.org/country.html).</DESCRIPTION>
                            <FIELD_TYPE>
                                  <TEXT_CHOICE_FIELD>
                                      <TEXT_VALUE>
                                            <VALUE>Blueland</VALUE>
                                      </TEXT_VALUE>
                                      <TEXT_VALUE>
                                            <VALUE>Republic of Goldland</VALUE>
                                      </TEXT_VALUE>
                                      <TEXT_VALUE>
                                            <VALUE>East Westland</VALUE>
                                      </TEXT_VALUE>
                                      <TEXT_VALUE>
                                            <VALUE>not applicable</VALUE>
                                      </TEXT_VALUE>
                                      <TEXT_VALUE>
                                            <VALUE>not collected</VALUE>
                                      </TEXT_VALUE>
                                      <TEXT_VALUE>
                                            <VALUE>not provided</VALUE>
                                      </TEXT_VALUE>
                                      <TEXT_VALUE>
                                            <VALUE>restricted access</VALUE>
                                      </TEXT_VALUE>
                                  </TEXT_CHOICE_FIELD>
                            </FIELD_TYPE>
                            <MANDATORY>optional</MANDATORY>
                            <MULTIPLICITY>multiple</MULTIPLICITY>
                        </FIELD>
                  </FIELD_GROUP>
              </DESCRIPTOR>
        </CHECKLIST>
    </CHECKLIST_SET>
  XML

  describe '#download' do
    context 'when the file already exists' do
      before { allow(File).to receive(:exist?).with(cached_file_path).and_return(true) }

      it 'does nothing' do
        importer.download
        expect(WebMock).not_to have_requested(:get, "#{ena_root}#{sample_checklist}")
      end
    end

    context 'when we force the download' do
      before do
        allow(File).to receive(:exist?).with(cached_file_path).and_return(true)
        stub_request(:get, "#{ena_root}#{sample_checklist}").to_return(body: mock_response)
        allow(File).to receive(:write)
      end

      it 'downloads the file' do
        expect(File).to receive(:write).with(cached_file_path, mock_response)
        importer.download(force: true)
      end
    end

    context 'when the file does not exist' do
      before do
        allow(File).to receive(:exist?).with(cached_file_path).and_return(false)
        stub_request(:get, "#{ena_root}#{sample_checklist}").to_return(body: mock_response)
        allow(File).to receive(:write)
      end

      it 'downloads the file' do
        expect(File).to receive(:write).with(cached_file_path, mock_response)
        importer.download
      end
    end
  end

  describe '#import' do
    context 'when the file is missing' do
      it 'raises an exception' do
        expect { importer.import }.to raise_error(
          StandardError,
          "Could not find #{cached_file_path}. Please ensure file is downloaded first."
        )
      end
    end

    context 'when the file is present' do
      before do
        create(:insdc_country, name: 'Historic Coldland')
        create(:insdc_country, name: 'East Westland')
        allow(File).to receive(:exist?).with(cached_file_path).and_return(true)
        allow(File).to receive(:open).with(cached_file_path).and_yield(mock_response)
        importer.import
      end

      it 'adds new entries' do
        added_country = Insdc::Country.find_by!(name: 'Blueland')
        expect(added_country).to have_attributes(name: 'Blueland', sort_priority: 0, validation_state: 'valid')
      end

      it 'invalidates old entries' do
        added_country = Insdc::Country.find_by!(name: 'Historic Coldland')
        expect(added_country).to have_attributes(
          name: 'Historic Coldland',
          sort_priority: 0,
          validation_state: 'invalid'
        )
      end

      it 'can set priorities' do
        added_country = Insdc::Country.find_by!(name: 'not applicable')
        expect(added_country).to have_attributes(name: 'not applicable', sort_priority: 1, validation_state: 'valid')
      end
    end
  end
end
