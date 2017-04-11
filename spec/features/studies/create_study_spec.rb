# frozen_string_literal: true
require 'rails_helper'

feature 'Create a study' do
  let(:user) { create :admin }
  let!(:faculty_sponsor) { create :faculty_sponsor, name: 'Jack Sponsor' }

  scenario 'create managed study', js: true do
    login_user user
    visit root_path
    click_link 'Create Study'
    expect(page).to have_content('Study Create')
    select('Managed (EGA)', from: 'study_study_metadata_attributes_data_release_strategy')
    expect(page).to have_content('HMDMC approval number')
    click_button 'Create'
    expect(page).not_to have_content "Study metadata hmdmc approval number can't be blank"
  end

  scenario 'create open study', js: true do
    login_user user
    visit new_study_path
    expect(page).to have_content('Study Create')
    expect(page).to have_content('Alignments in BAM')
    bam = find('#study_study_metadata_attributes_bam')
    expect(bam).to be_checked
    uncheck 'study_study_metadata_attributes_bam'
    expect(bam).not_to be_checked
    fill_in 'Study name', with: 'new study'
    fill_in 'Study description', with: 'writing cukes'
    fill_in 'ENA Study Accession Number', with: '12345'
    fill_in 'Study name abbreviation', with: 'CCC3'
    select('Jack Sponsor', from: 'Faculty Sponsor')
    select('Yes', from: 'Do any of the samples in this study contain human DNA?')
    select('No', from: 'Does this study contain samples that are contaminated with human DNA which must be removed prior to analysis?')
    select('No', from: 'Does this study require the removal of X chromosome and autosome sequence?')
    select('Open (ENA)', from: 'study_study_metadata_attributes_data_release_strategy')
    expect(page).not_to have_content('HMDMC approval number')
    click_button 'Create'
    expect(page).to have_content('Your study has been created')
    study = Study.last
    expect(page).to have_current_path("/studies/#{study.id}/workflows/#{Submission::Workflow.last.id}")
    expect(study.abbreviation).to eq 'CCC3'
    expect(study.study_metadata.bam).to eq false
  end
end
