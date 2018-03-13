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
    click_button 'Save Study'
    expect(page).to have_content('Your study has been updated')
    click_link 'Study details'
    expect(page).to have_content('Alignments in BAM: true')
  end

  scenario 'add external customer information', js: true do
    login_user(user)
    visit study_path(study)
    click_link 'Edit'
    fill_in 'S3 email list', with: 'aa1@sanger.ac.uk;aa2@sanger.ac.uk;aa3@sanger.ac.uk'
    select('3 months', from: 'Data deletion period')
    click_button 'Save Study'
    expect(page).to have_content('Your study has been updated')
    study.reload
    expect(study.study_metadata.s3_email_list).to eq('aa1@sanger.ac.uk;aa2@sanger.ac.uk;aa3@sanger.ac.uk')
    expect(study.study_metadata.data_deletion_period).to eq('3 months')
  end
end
