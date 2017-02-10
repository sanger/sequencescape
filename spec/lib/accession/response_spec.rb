require 'rails_helper'

RSpec.describe Accession::Response, type: :model, accession: true do
  include MockAccession

  it 'should be successful if the status code is in the correct range' do
    expect(Accession::Response.new(MockAccession::Response.new(200, ''))).to be_success
    expect(Accession::Response.new(MockAccession::Response.new(201, ''))).to be_success
    expect(Accession::Response.new(MockAccession::Response.new(300, ''))).to be_success
    expect(Accession::Response.new(MockAccession::Response.new(400, ''))).to_not be_success
    expect(Accession::Response.new(MockAccession::Response.new(500, ''))).to_not be_success
  end

  it 'should be a failure if the status code is in the correct range' do
    expect(Accession::Response.new(MockAccession::Response.new(200, ''))).to_not be_failure
    expect(Accession::Response.new(MockAccession::Response.new(300, ''))).to_not be_failure
    expect(Accession::Response.new(MockAccession::Response.new(400, ''))).to be_failure
    expect(Accession::Response.new(MockAccession::Response.new(500, ''))).to be_failure
    expect(Accession::Response.new(MockAccession::Response.new(600, ''))).to be_failure
  end

  it 'if it is a failure should have no accession number or errors' do
    response = Accession::Response.new(MockAccession::Response.new(500, ''))
    expect(response).to_not be_accessioned
    expect(response.accession_number).to_not be_present
    expect(response.errors).to_not be_present
  end

  it 'should have an accession number if accessioning has been successful' do
    response = Accession::Response.new(successful_accession_response)
    expect(response).to be_accessioned
    expect(response.accession_number).to eq('EGA00001000240')
    expect(response.errors).to_not be_present
  end

  it 'should have some errors if accessioning was not successful' do
    response = Accession::Response.new(failed_accession_response)
    expect(response).to_not be_accessioned
    expect(response.accession_number).to_not be_present
    expect(response.errors).to eq(['Error 1', 'Error 2'])
  end
end
