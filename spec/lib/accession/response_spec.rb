require 'rails_helper'

RSpec.describe Accession::Response, type: :model, accession: true do

  MockAccessionResponse = Struct.new(:code, :body)

  let(:success) { '<RECEIPT success="true"><SAMPLE accession="EGA00001000240" /></RECEIPT>' }
  let(:failure) { '<RECEIPT success="false"><ERROR>Error 1</ERROR><ERROR>Error 2</ERROR></RECEIPT>' }

  it "should be successful if the status code is in the correct range" do
    expect(Accession::Response.new(MockAccessionResponse.new(200, ""))).to be_success
    expect(Accession::Response.new(MockAccessionResponse.new(201, ""))).to be_success
    expect(Accession::Response.new(MockAccessionResponse.new(300, ""))).to be_success
    expect(Accession::Response.new(MockAccessionResponse.new(400, ""))).to_not be_success
    expect(Accession::Response.new(MockAccessionResponse.new(500, ""))).to_not be_success
  end

  it "should be a failure if the status code is in the correct range" do
    expect(Accession::Response.new(MockAccessionResponse.new(200, ""))).to_not be_failure
    expect(Accession::Response.new(MockAccessionResponse.new(300, ""))).to_not be_failure
    expect(Accession::Response.new(MockAccessionResponse.new(400, ""))).to be_failure
    expect(Accession::Response.new(MockAccessionResponse.new(500, ""))).to be_failure
    expect(Accession::Response.new(MockAccessionResponse.new(600, ""))).to be_failure
  end

  it "should have an accession number if accessioning has been successful" do
    response = Accession::Response.new(MockAccessionResponse.new(200, success))
    expect(response).to be_accessioned
    expect(response.accession_number).to eq("EGA00001000240")
    expect(response.errors).to_not be_present
  end

  it "should have some errors if accessioning was not successful" do
    response = Accession::Response.new(MockAccessionResponse.new(200, failure))
    expect(response).to_not be_accessioned
    expect(response.accession_number).to_not be_present
    expect(response.errors).to eq(["Error 1", "Error 2"])
  end

end