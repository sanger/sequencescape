# frozen_string_literal: true
require 'rails_helper'

feature 'Edit a study' do
  let(:user) { create :admin }
  let!(:study) { create :study }

  scenario 'edit open study', js: true do
    study.study_metadata.bam = false
    study.save
    login_user(user)
    visit study_path(study)
    click_link 'Edit'
    expect(page).to have_content('Alignments in BAM')
    expect(find('#study_study_metadata_attributes_bam')).not_to be_checked
    check 'study_study_metadata_attributes_bam'
    expect(find('#study_study_metadata_attributes_bam')).to be_checked
    click_button 'Update'
    expect(page).to have_content('Your study has been updated')
    click_link 'Study details'
    expect(page).to have_content('Alignments in BAM: true')
  end
end
