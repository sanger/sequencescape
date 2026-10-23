# frozen_string_literal: true

require 'rails_helper'

# Migrated from features/administration/71118369_reference_genome_admin_interface.feature
describe 'Manage reference genomes' do
  include StudyFormHelper

  let(:admin) { create(:admin) }

  before { login_user admin }

  it 'creates a reference genome' do
    visit root_path
    click_link 'Admin'
    click_link 'Reference genome management'
    click_link 'New reference genome'
    fill_in 'Name', with: 'BlahBlahBlah'
    click_button 'Create'

    expect(page).to have_text('Reference genome was successfully created.')
    expect(ReferenceGenome.find_by(name: 'BlahBlahBlah')).to be_present
  end

  it 'edits a reference genome' do
    create(:reference_genome, name: 'WibbleWibble')

    visit reference_genomes_path
    click_link 'Edit'
    expect(page).to have_text('Editing reference genome')
    fill_in 'Name', with: 'WibbleWibble2'
    click_button 'Update'
    expect(page).to have_text('Reference genome was successfully updated.')

    click_link 'Back'
    expect(page).to have_text('Listing reference genomes')
    expect(page).to have_text('WibbleWibble2')
  end

  it 'offers a newly added reference genome when creating a study', :js do
    create_study_form_reference_data
    enable_ui_study_creation
    create(:reference_genome, name: 'Mus_musculus (NCBIm37)')

    visit new_study_path
    expect(page).to have_select('Reference genome', with_options: ['Mus_musculus (NCBIm37)'])

    fill_in_study_details(name: 'Cucumber1', description: 'parp parp')
    select 'Mus_musculus (NCBIm37)', from: 'Reference genome'
    choose_data_release_strategy 'Open (ENA)'
    click_button 'Create'

    expect(page).to have_text('Your study has been created')
    expect(Study.find_by!(name: 'Cucumber1').study_metadata.reference_genome.name).to eq('Mus_musculus (NCBIm37)')
  end
end
