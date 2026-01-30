# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'EGA DAC and Policy accessioning', :accessioning_enabled, :js, type: :feature do
  include MockAccession

  let(:user) { create(:admin) }
  let(:data_access_contacts) { create_list(:user, 1) }

  before do
    login_user(user)
  end

  context 'when a managed study has a valid DAC set but no accession number for it' do
    let(:study) { create(:managed_study, :with_data_access_contacts, data_access_contacts:) }

    before do
      allow_any_instance_of(RestClient::Resource).to receive(:post)
        .and_return(successful_dac_policy_accession_response)

      visit study_path(study)
    end

    it 'generates a DAC accession number and displays it on study details' do
      click_link 'Generate DAC Accession Number'
      visit study_information_path(study)
      click_link 'Study details'
      expect(page).to have_content('EGAD0001000234')
    end
  end

  context 'when an open study has a valid DAC set but no accession number for it' do
    let(:study) { create(:open_study, :with_data_access_contacts, data_access_contacts:) }

    before do
      allow_any_instance_of(RestClient::Resource).to receive(:post).and_return(failed_accession_response)
      visit study_path(study)
    end

    it 'does not generate a DAC accession number' do
      click_link 'Generate DAC Accession Number'
      expect(page).to have_content('No accession number was generated')
    end
  end

  context 'when a managed study has a valid Policy set but no accession number for it' do
    let(:study) { create(:managed_study, :with_data_access_contacts, data_access_contacts:) }

    before do
      allow_any_instance_of(RestClient::Resource).to receive(:post)
        .and_return(successful_dac_policy_accession_response)

      study.study_metadata.update(ega_dac_accession_number: 'EGAD0001000234') # DAC required prior to Policy

      visit study_path(study)
    end

    it 'generates a Policy accession number and displays it on study details' do
      click_link 'Generate Policy Accession Number'
      visit study_information_path(study)
      click_link 'Study details'
      expect(page).to have_content('EGAP0001000234')
    end
  end

  context 'when an open study has a valid Policy set but no accession number for it' do
    let(:study) { create(:open_study, :with_data_access_contacts, data_access_contacts:) }

    before do
      allow_any_instance_of(RestClient::Resource).to receive(:post).and_return(failed_accession_response)

      visit study_path(study)
    end

    it 'does not generate a Policy accession number' do
      click_link 'Generate Policy Accession Number'
      expect(page).to have_content('No accession number was generated')
    end
  end

  context 'when a managed study has an invalid DAC' do
    let(:study) { create(:managed_study) } # no data access contacts

    before do
      visit study_path(study)
    end

    it 'shows error and does not display accession number on study details' do
      click_link 'Generate DAC Accession Number'
      expect(page).to have_content('Data Access Contacts Empty')
    end
  end
end
