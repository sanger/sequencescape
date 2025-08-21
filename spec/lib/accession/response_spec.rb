# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Accession::Response, :accession, type: :model do
  include MockAccession

  it 'is successful if the status code is in the correct range' do
    expect(described_class.new(MockAccession::Response.new(200, ''))).to be_success
    expect(described_class.new(MockAccession::Response.new(201, ''))).to be_success
    expect(described_class.new(MockAccession::Response.new(300, ''))).to be_success
    expect(described_class.new(MockAccession::Response.new(400, ''))).not_to be_success
    expect(described_class.new(MockAccession::Response.new(500, ''))).not_to be_success
  end

  it 'is a failure if the status code is in the correct range' do
    expect(described_class.new(MockAccession::Response.new(200, ''))).not_to be_failure
    expect(described_class.new(MockAccession::Response.new(300, ''))).not_to be_failure
    expect(described_class.new(MockAccession::Response.new(400, ''))).to be_failure
    expect(described_class.new(MockAccession::Response.new(500, ''))).to be_failure
    expect(described_class.new(MockAccession::Response.new(600, ''))).to be_failure
  end

  it 'if it is a failure should have no accession number or errors' do
    response = described_class.new(MockAccession::Response.new(500, ''))
    expect(response).not_to be_accessioned
    expect(response.accession_number).not_to be_present
    expect(response.errors).not_to be_present
  end

  it 'has an accession number if accessioning has been successful' do
    response = described_class.new(successful_sample_accession_response)
    expect(response).to be_accessioned
    expect(response.accession_number).to eq('EGA00001000240')
    expect(response.errors).not_to be_present
  end

  it 'has some errors if accessioning was not successful' do
    response = described_class.new(failed_accession_response)
    expect(response).not_to be_accessioned
    expect(response.accession_number).not_to be_present
    expect(response.errors).to eq(['Error 1', 'Error 2'])
  end
end
