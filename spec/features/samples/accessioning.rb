# frozen_string_literal: true
require 'rails_helper'

feature 'Accession a sample' do
  let!(:admin)    { create(:admin) }
  let!(:user)     { create(:user, api_key: configatron.accession_local_key) }

  before(:each) do
    Accession.configure do |config|
      config.folder = File.join('spec', 'data', 'accession')
      config.load!
    end
  end

  scenario 'successfully' do
    sample = create(:sample_for_accessioning_with_open_study, sample_metadata: create(:sample_metadata_for_accessioning))
    allow(Accession::Request).to receive(:post).and_return(build(:successful_accession_response))
    login_user admin
    visit sample_path(sample.id)
    click_link 'Generate Accession Number'
    expect(page).to have_content("Accession number generated: #{sample.reload.sample_metadata.sample_ebi_accession_number}")
  end

  scenario 'when the accessioning service is down or accessioning fails' do
    sample = create(:sample_for_accessioning_with_open_study, sample_metadata: create(:sample_metadata_for_accessioning))
    allow(Accession::Request).to receive(:post).and_return(build(:failed_accession_response))
    login_user admin
    visit sample_path(sample.id)
    click_link 'Generate Accession Number'
    expect(page).to have_content("The sample could not be accessioned")
  end

  scenario 'when the sample is invalid' do
    sample = create(:sample)
    login_user admin
    visit sample_path(sample.id)
    click_link 'Generate Accession Number'
    expect(page).to have_content("Sample has no appropriate studies")
  end

  after(:each) do
    Accession.reset!
  end
end