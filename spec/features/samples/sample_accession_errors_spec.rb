# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Sample accession errors', :js, type: :feature do
  let(:user) { create(:admin) }
  let(:study) { create(:managed_study, accession_number: 'ENA123') }

  before do
    login_user(user)
    visit sample_path(sample)
  end

  context 'when the sample has not been accessioned' do
    let(:sample) { create(:sample, studies: [study]) }

    context 'when accessioning is enabled', :accessioning_enabled do
      it 'shows informative errors when required fields are missing for accessioning' do
        expect(page).to have_content('Sample Specification')
        expect(page).to have_link('Generate Accession Number')
      end
    end

    context 'when accessioning is disabled' do
      it 'shows a disabled link for accessioning' do
        expect(page).to have_content('Sample Specification')
        expect(page).to have_content('Generate Accession Number')
        expect(page).to have_no_link('Generate Accession Number')
      end
    end
  end

  context 'when the sample has been accessioned' do
    let(:sample) { create(:accessioned_sample, studies: [study]) }

    context 'when accessioning is enabled', :accessioning_enabled do
      it 'shows a link for accessioning' do
        expect(page).to have_content('Sample Specification')
        expect(page).to have_link('Update Sample Data for Accessioning')
      end
    end

    context 'when accessioning is disabled' do
      it 'shows a disabled link for accessioning' do
        expect(page).to have_content('Sample Specification')
        expect(page).to have_content('Update Sample Data for Accessioning')
        expect(page).to have_no_link('Update Sample Data for Accessioning')
      end
    end
  end
end
