# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Accession::Submission, :accession, type: :model do
  include AccessionV1ClientHelper

  let!(:user) { create(:user) }
  let!(:sample) { build(:accession_sample) }

  context 'when validating' do
    it 'is not valid without a user' do
      expect(described_class.new(user, nil)).not_to be_valid
    end

    it 'is not valid without an accession sample' do
      expect(described_class.new(nil, sample)).not_to be_valid
    end

    it 'is not valid unless sample is valid' do
      expect(described_class.new(user, build(:invalid_accession_sample))).not_to be_valid
    end
  end

  describe '#to_xml' do
    it 'creates some xml with valid attributes' do
      submission = described_class.new(user, sample)
      xml = Nokogiri::XML::Document.parse(submission.to_xml)

      submission_xml = xml.at('SUBMISSION')
      expect(submission_xml.attribute('center_name').value).to eq(Accession::CENTER_NAME)
      expect(submission_xml.attribute('broker_name').value).to eq(submission.service.broker)
      expect(submission_xml.attribute('alias').value).to eq(submission.sample.ebi_alias_datestamped)
      expect(submission_xml.attribute('submission_date').value).to eq(submission.date)

      contact_xml = xml.at('CONTACT')
      submission.contact.to_h.each do |attribute, value|
        expect(contact_xml.attribute(attribute.to_s).value).to eq(value)
      end

      expect(xml.at(submission.service.visibility)).to be_present

      expect(xml.at('ACTIONS').children.length).to eq(2)

      action_xml = xml.at('ADD')
      expect(action_xml.attribute('source').value).to eq(submission.sample.filename)
      expect(action_xml.attribute('schema').value).to eq(submission.sample.schema_type)
    end
  end

  describe '#payload' do
    it 'creates a payload' do
      payload = described_class.new(user, sample).payload
      expect(payload.count).to eq(2)
      expect(payload).to be_all { |_, file| File.file?(file) }
      expect(payload).to be_all { |key, _| key.match(/\p{Lower}/).nil? }
    end
  end

  describe '#submit_and_update_accession_number' do
    let(:submission) { described_class.new(user, sample) }

    before do
      # Inject the mocked client into the controller
      allow(described_class).to receive(:client).and_return(mock_client)
    end

    context 'when the submission is successful' do
      let(:accession_number) { 'EGA00001000240' }
      let(:mock_client) do
        stub_accession_client(:submit_and_fetch_accession_number, submission, return_value: accession_number)
      end

      before do
        expect(submission.sample).not_to be_accessioned

        submission.submit_and_update_accession_number
      end

      it 'updates the sample accession number' do
        expect(submission).to be_accessioned
      end
    end

    context 'when the submission fails validation' do
      let(:invalid_submission) { described_class.new(nil, nil) }
      let(:mock_client) { nil } # Client should not be called

      it 'raises an error with a message' do
        error_message = "Accessionable submission is invalid: User can't be blank, Sample can't be blank"
        expect { invalid_submission.submit_and_update_accession_number }.to raise_error(StandardError, error_message)
      end

      context 'when the sample is invalid due to already being accessioned' do
        let(:invalid_submission) { described_class.new(user, build(:invalid_accession_sample)) }

        it 'raises an error with a message' do
          error_message = 'Accessionable submission is invalid: Sample has already been accessioned.'
          expect { invalid_submission.submit_and_update_accession_number }.to raise_error(StandardError, error_message)
        end
      end
    end

    context 'when the submission fails due to an accessioning error' do
      let(:mock_client) do
        stub_accession_client(:submit_and_fetch_accession_number, submission,
                              raise_error: Accession::Error.new('Posting of accession submission failed'))
      end

      it 'does not update the sample accession number' do
        expect(submission).not_to be_accessioned
      end

      it 'bubbles up the Accession::Error' do
        expect do
          submission.submit_and_update_accession_number
        end.to raise_error(Accession::Error, 'Posting of accession submission failed')
      end
    end
  end
end
