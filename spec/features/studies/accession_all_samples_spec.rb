# frozen_string_literal: true

require 'rails_helper'

describe 'Accession all samples' do
  let!(:user) { create(:user, api_key: configatron.accession_local_key) }
  let!(:study) { create(:open_study, accession_number: 'ENA123', samples: create_list(:sample_for_accessioning, 5)) }

  before do
    Delayed::Worker.delay_jobs = false
    configatron.accession_samples = true
    Accession.configure do |config|
      config.folder = File.join('spec', 'data', 'accession')
      config.load!
    end
    allow(Accession::Request).to receive(:post).and_return(build(:successful_accession_response))
  end

  after do
    configatron.accession_samples = false
    Delayed::Worker.delay_jobs = true
    SampleManifestExcel.reset!
  end

  it 'accession all samples' do
    login_user user
    visit study_path(study.id)
    click_link 'Accession all Samples'
    expect(page).to have_content('All of the samples in this study have been sent for accessioning.')
    expect(study.reload.samples).to(be_all { |sample| sample.sample_metadata.sample_ebi_accession_number.present? })
  end
end
