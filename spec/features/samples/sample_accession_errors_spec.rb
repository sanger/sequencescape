# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Sample accession errors', type: :feature do
  let(:user) { create(:admin) }
  let(:study) { create(:managed_study, accession_number: 'ENA123') }
  let(:sample) { create(:sample, studies: [study]) }

  before do
    login_user(user)
    visit sample_path(sample)
  end

  context 'when accessioning is enabled', :accessioning_enabled do
    it 'shows informative errors when required fields are missing for accessioning' do
      expect(page).to have_content('Sample Specification')
      expect(page).to have_content('Generate Accession Number')
      click_link 'Generate Accession Number'
      expect(page).to have_content('Please fill in the required fields:')
      expect(page).to have_content('gender is required')
      expect(page).to have_content('phenotype is required')
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
