require 'rails_helper'

RSpec.describe Accession::Operation, type: :model, accession: true do
  let!(:user) { create(:user) }
  let(:tag_list) { build(:standard_accession_tag_list) }

  it 'will produce errors if the sample is not accessionable' do
    operation = Accession::Operation.new(user, create(:sample), tag_list)
    expect(operation).to_not be_valid
    expect(operation.errors).to_not be_empty
  end

  it 'will produce errors if the sample cannot be accessioned' do
    allow(Accession::Request).to receive(:post).and_return(build(:failed_accession_response))
    sample = create(:sample_for_accessioning_with_open_study, sample_metadata: create(:sample_metadata_for_accessioning))
    operation = Accession::Operation.new(user, sample, tag_list)
    operation.execute
    expect(operation).to_not be_success
    expect(sample.sample_metadata.sample_ebi_accession_number).to be_nil
  end

  it 'will add an accession number to the sample if it can be accessioned' do
    allow(Accession::Request).to receive(:post).and_return(build(:successful_accession_response))
    sample = create(:sample_for_accessioning_with_open_study, sample_metadata: create(:sample_metadata_for_accessioning))
    operation = Accession::Operation.new(user, sample, tag_list)
    operation.execute
    expect(operation).to be_success
    expect(sample.sample_metadata.sample_ebi_accession_number).to be_present
  end

  it 'will add a delayed job if delayed' do
    allow(Accession::Request).to receive(:post).and_return(build(:successful_accession_response))
    operation = Accession::Operation.new(user, create(:sample_for_accessioning_with_open_study, sample_metadata: create(:sample_metadata_for_accessioning)), tag_list, true)
    expect { operation.execute }.to change(Delayed::Job, :count).by(1)
  end
end
