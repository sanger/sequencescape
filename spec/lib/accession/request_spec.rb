require 'rails_helper'

RSpec.describe Accession::Request, type: :model, accession: true do

  let(:submission) { build(:accession_submission) }

  it "should not be valid without a submission" do
    expect(Accession::Request.new(nil)).to_not be_valid
  end

  it "should have a resource" do
    expect(Accession::Request.new(submission).resource).to_not be_nil
  end

  describe "#post" do
    
  end
end