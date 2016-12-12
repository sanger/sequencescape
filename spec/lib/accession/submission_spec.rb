require 'rails_helper'

RSpec.describe Accession::Submission, type: :model, accession: true do

  let!(:user)     { create(:user) }
  let!(:sample)   { build(:accession_sample) }

  it "should not be valid without a user" do
    expect(Accession::Submission.new(user, nil)).to_not be_valid
  end

  it "should not be valid without an accession sample" do
    expect(Accession::Submission.new(nil, sample)).to_not be_valid
  end

  it "should create some xml with valid attributes" do
    submission = Accession::Submission.new(user, sample)
    xml = Nokogiri::XML::Document.parse(submission.to_xml)

    submission_xml = xml.at("SUBMISSION")
    expect(submission_xml.attribute("center_name").value).to eq(Accession::CENTER_NAME)
    expect(submission_xml.attribute("broker_name").value).to eq(submission.service.broker)
    expect(submission_xml.attribute("alias").value).to eq(submission.sample.submission_alias)
    expect(submission_xml.attribute("submission_date").value).to eq(submission.date)

    contact_xml = xml.at("CONTACT")
    submission.contact.to_h.each do |attribute, value|
      expect(contact_xml.attribute(attribute.to_s).value).to eq(value)
    end

    expect(xml.at(submission.service.visibility)).to be_present

    action_xml = xml.at("ADD")
    expect(action_xml.attribute("source").value).to eq(submission.sample.filename)
    expect(action_xml.attribute("schema").value).to eq(submission.sample.schema_type)
  end
end