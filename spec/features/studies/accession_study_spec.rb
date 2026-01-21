# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Study accession number', :accessioning_enabled, :js, type: :feature do
  include MockAccession

  let(:user) { create(:admin, first_name: 'John', last_name: 'Smith') }
  let(:study) { create(:managed_study) }

  before do
    login_user(user)
    visit study_path(study)
  end

  context 'when the study does not need an accession number' do
    let(:study) { create(:study) }

    it 'shows not required message' do
      click_link 'Generate Accession Number'
      expect(page).to have_css('.alert', text: 'An accession number is not required for this study')
      expect(page).to have_current_path(study_information_path(study))
    end
  end

  context 'when the study already has an accession number' do
    before do
      allow_any_instance_of(RestClient::Resource).to receive(:post).and_return(successful_study_accession_response)

      study.study_metadata.update!(study_ebi_accession_number: 'EGAN00001000234')
      visit study_path(study)
    end

    it 'shows the generated accession number' do
      click_link 'Update Study Data for Accessioning'
      expect(page).to have_css('.alert', text: 'Accession number generated: EGA00002000345')
    end
  end

  context 'when required fields are missing' do
    %w[study_study_title study_abstract].each do |attribute|
      it "shows required fields message when #{attribute} is missing" do
        study.study_metadata.update!(attribute => '')
        visit study_path(study)
        click_link 'Generate Accession Number'
        expect(page).to have_css('.alert', text: 'Please fill in the required fields')
      end
    end
  end

  context 'when the study gets a valid accession number' do
    before do
      allow_any_instance_of(RestClient::Resource).to receive(:post).and_return(successful_study_accession_response)

      visit study_path(study)
    end

    it 'shows the generated accession number and displays it on study details' do
      click_link 'Generate Accession Number'
      expect(page).to have_css('.alert', text: 'Accession number generated: EGA00002000345')
      visit study_path(study)
      click_link 'Study details'
      expect(page).to have_content('EGA00002000345')
    end
  end

  context 'when the accession number service gives an error' do
    before do
      allow_any_instance_of(RestClient::Resource).to receive(:post).and_return(failed_accession_response)

      visit study_path(study)
    end

    it 'shows the error message' do
      click_link 'Generate Accession Number'
      expect(page).to have_css('.alert', text: 'Error 1; Error 2')
    end
  end

  context 'when the accession number service is unavailable' do
    before do
      allow_any_instance_of(RestClient::Resource).to receive(:post).and_raise(RestClient::ServiceUnavailable)

      visit study_path(study)
    end

    it 'shows the unavailable message' do
      click_link 'Generate Accession Number'
      expect(page).to have_css('.alert', text: 'EBI may be down or invalid data submitted')
    end
  end
end
