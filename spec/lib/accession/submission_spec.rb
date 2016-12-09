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

  # it "should have some xml attributes" do
  #   submission = Accession::Submission.new(user, sample)
  #   xml_attributes = submission.xml_attributes
  #   expect(xml_attributes.count).to eq(5)
  #   expect(xml_attributes[:center_name]).to eq("SC")
  #   expect(xml_attributes[:broker_name]).to eq(sample.service.broker)
  #   expect(xml_attributes[:alias]).to include(submission.date)
  #   expect(xml_attributes[:submission_date]).to eq(submission.date)
  # end
end