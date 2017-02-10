require 'rails_helper'

RSpec.describe Accession::Submission, type: :model, accession: true do
  let!(:user)     { create(:user) }
  let!(:sample)   { build(:accession_sample) }

  it 'should not be valid without a user' do
    expect(Accession::Submission.new(user, nil)).to_not be_valid
  end

  it 'should not be valid without an accession sample' do
    expect(Accession::Submission.new(nil, sample)).to_not be_valid
  end

  it 'should not be valid unless sample is valid' do
    expect(Accession::Submission.new(user, build(:invalid_accession_sample))).to_not be_valid
  end

  it 'should create some xml with valid attributes' do
    submission = Accession::Submission.new(user, sample)
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

  it 'should create a payload' do
    payload = Accession::Submission.new(user, sample).payload
    expect(payload.count).to eq(2)
    expect(payload.all? { |_, file| File.file?(file) }).to be_truthy
    expect(payload.all? { |key, _| key.match(/\p{Lower}/).nil? }).to be_truthy
  end

  it 'should post the submission and return an appropriate response' do
    submission = Accession::Submission.new(user, sample)

    allow(Accession::Request).to receive(:post).with(submission).and_return(build(:successful_accession_response))
    submission.post
    expect(submission).to be_accessioned

    allow(Accession::Request).to receive(:post).with(submission).and_return(build(:failed_accession_response))
    submission.post
    expect(submission).to_not be_accessioned
  end

  it 'should update the accession number if the submission is successfully posted' do
    submission = Accession::Submission.new(user, sample)
    submission.update_accession_number
    expect(submission.sample).to_not be_accessioned

    allow(Accession::Request).to receive(:post).with(submission).and_return(build(:successful_accession_response))
    submission.post
    submission.update_accession_number
    expect(submission.sample).to be_accessioned
  end
end
