# frozen_string_literal: true

require 'rails_helper'

describe 'Accession all samples', :accessioning_enabled, :un_delay_jobs do
  include AccessionV1ClientHelper

  let(:user) { create(:admin, api_key: configatron.accession_local_key) } # admin required for accession permissions
  let(:study) { create(:open_study, accession_number: 'ENA123', samples: create_list(:sample_for_accessioning, 5)) }

  before do
    allow(Accession::Submission).to receive(:client).and_return(
      stub_accession_client(:submit_and_fetch_accession_number, return_value: 'EGA00001000240')
    )
  end

  after do
    SampleManifestExcel.reset!
  end

  it 'accession all samples' do
    login_user user
    visit study_path(study.id)
    click_link 'Accession all Samples'
    expect(page).to have_content('All of the samples in this study have been sent for accessioning.')
    expect(study.reload.samples).to be_all { |sample| sample.sample_metadata.sample_ebi_accession_number.present? }
  end
end
