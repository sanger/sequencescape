# frozen_string_literal: true

require 'rails_helper'

describe 'Edit a study' do
  let(:user) { create(:admin) }
  let!(:study) { create(:study) }

  it 'edit open study', :js do
    study.study_metadata.bam = false
    study.save
    login_user(user)
    visit study_path(study)
    click_link 'Edit'
    expect(page).to have_content('Alignments in BAM')
    expect(find_by_id('study_study_metadata_attributes_bam')).not_to be_checked
    check 'study_study_metadata_attributes_bam'
    expect(find_by_id('study_study_metadata_attributes_bam')).to be_checked
    click_button 'Save Study'
    expect(page).to have_content('Your study has been updated')
    click_link 'Study details'
    expect(page).to have_content('Alignments in BAM: true')
  end

  it 'add external customer information', :js do
    login_user(user)
    visit study_path(study)
    click_link 'Edit'
    fill_in 'S3 email list', with: 'aa1@sanger.ac.uk;aa2@sanger.ac.uk;aa3@sanger.ac.uk',
                             fill_options: { clear: :backspace }
    select('3 months', from: 'Data deletion period')
    click_button 'Save Study'
    expect(page).to have_content('Your study has been updated')
    study.reload
    expect(study.study_metadata.s3_email_list).to eq('aa1@sanger.ac.uk;aa2@sanger.ac.uk;aa3@sanger.ac.uk')
    expect(study.study_metadata.data_deletion_period).to eq('3 months')
  end

  context 'when data release strategy is Not Applicable' do
    let!(:study) { create(:not_app_study) }

    it 'does not error when setting strategy to Open', :js do
      study.study_metadata.data_release_strategy = 'not applicable'
      study.save
      login_user(user)
      visit study_path(study)
      click_link 'Edit'
      expect(page).to have_content('What is the data release strategy for this study?')
      expect(page).to have_content('Open (ENA)')
      choose('Open (ENA)', allow_label_click: true)
      click_button 'Save Study'
      expect(page).to have_content('Your study has been updated')
    end
  end

  context 'with data release strategy' do
    before do
      login_user user
      visit study_path study
      click_link 'Edit'
    end

    it 'displays HuMFre approval number when Open (ENA) is clicked' do
      choose('Open (ENA)', allow_label_click: true)
      expect(page).to have_field('HuMFre approval number', type: :text)
    end

    it 'displays HuMFre approval number when Managed (EGA) is clicked' do
      choose('Managed (EGA)', allow_label_click: true)
      expect(page).to have_field('HuMFre approval number', type: :text)
    end

    it 'displays HuMFre approval number when Not Applicable is clicked' do
      choose('Not Applicable', allow_label_click: true)
      expect(page).to have_field('HuMFre approval number', type: :text)
    end
  end
end
