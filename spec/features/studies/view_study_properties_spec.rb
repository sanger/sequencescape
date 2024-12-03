# frozen_string_literal: true

require 'rails_helper'

describe 'View study properties' do
  let(:user) { create(:admin) }
  let(:prelim_id) { 'A1234' }
  let(:study) { create(:study, study_metadata: create(:study_metadata, prelim_id:)) }

  it 'view open study properties', :js do
    login_user(user)
    visit study_path(study)
    click_link 'Study details'
    expect(page).to have_content('Alignments in BAM: true')
    expect(page).to have_content('HuMFre approval number: ')
    expect(page).to have_content("Prelim ID: #{prelim_id}")
  end

  it 'view properties of a study that requires ethical approval' do
    study.study_metadata = create :study_metadata_for_study_list_pending_ethical_approval
    study.study_metadata.hmdmc_approval_number = '12345'
    study.save

    login_user(user)
    visit study_path(study)
    click_link 'Study details'
    expect(page).to have_content('HuMFre approval number: 12345')
  end

  context 'with data release strategy' do
    it 'displays HuMFre approval number for Open(ENA) data release strategy' do
      study.study_metadata.data_release_strategy = Study::DATA_RELEASE_STRATEGY_OPEN
      study.study_metadata.hmdmc_approval_number = '12345'
      study.study_metadata.save!

      login_user(user)
      visit study_path(study)
      click_link 'Study details'
      expect(page).to have_content('What is the data release strategy for this study?: open')
      expect(page).to have_content('HuMFre approval number: 12345')
    end

    it 'displays HuMFre approval number for Managed(EGA) data release strategy' do
      study.study_metadata.data_release_strategy = Study::DATA_RELEASE_STRATEGY_MANAGED
      study.study_metadata.hmdmc_approval_number = '12345'
      study.study_metadata.save!

      login_user(user)
      visit study_path(study)
      click_link 'Study details'
      expect(page).to have_content('What is the data release strategy for this study?: managed')
      expect(page).to have_content('HuMFre approval number: 12345')
    end

    it 'displays HuMFre approval number for Not Applicable data release strategy' do
      study.study_metadata.data_release_strategy = Study::DATA_RELEASE_STRATEGY_NOT_APPLICABLE
      study.study_metadata.data_release_timing = Study::DATA_RELEASE_TIMING_NEVER
      study.study_metadata.data_release_prevention_reason = Study::DATA_RELEASE_PREVENTION_REASONS[0]
      study.study_metadata.data_release_prevention_approval = Study::YES
      study.study_metadata.data_release_prevention_reason_comment = 'comment'
      study.study_metadata.hmdmc_approval_number = '12345'
      study.study_metadata.save!

      login_user(user)
      visit study_path(study)
      click_link 'Study details'
      expect(page).to have_content('What is the data release strategy for this study?: not applicable')
      expect(page).to have_content('HuMFre approval number: 12345')
    end
  end
end
