# frozen_string_literal: true

require 'rails_helper'

# Migrated from features/studies/data_release_timings.feature
RSpec.describe 'Study data release timings', :js do
  include StudyFormHelper

  let(:user) { create(:admin, first_name: 'John', last_name: 'Smith') }
  let(:study_name) { 'Testing data release strategies' }
  let(:approval_number_field) { 'If reason for exemption requires DAC approval, what is the approval number?' }

  before do
    create_study_form_reference_data
    enable_ui_study_creation
    login_user(user)
    visit new_study_path
    fill_in_study_details(
      name: study_name,
      description: 'Checking that the data release strategies behave appropriately'
    )
    choose_data_release_strategy('Open (ENA)')
  end

  context 'when the data release is open' do
    %w[standard immediate].each do |timing|
      it "creates the study when the data release is #{timing}" do
        select timing, from: 'How is the data release to be timed?'
        click_button 'Create'

        expect_to_be_on_information_page_for(study_name)
        expect(page).to have_text('Your study has been created')
      end
    end

    it 'creates the study when the data release is delayed for a PhD study' do
      select 'delayed', from: 'How is the data release to be timed?'
      select 'PhD study', from: 'Reason for delaying release'
      select '6 months', from: 'Delay for'
      click_button 'Create'

      expect_to_be_on_information_page_for(study_name)
      expect(page).to have_text('Your study has been created')
    end
  end

  context 'when the data release is never' do
    before do
      choose_data_release_strategy('Not Applicable')
      select 'never', from: 'How is the data release to be timed?'
    end

    it "doesn't create the study when the prevention 'other' comment is not supplied" do
      select 'Other (please specify)', from: 'What is the reason for preventing data release?'
      fill_in approval_number_field, with: '12345'
      click_button 'Create'

      expect(page).to have_current_path(studies_path)
      # Ideally this message would not mention the 'study metadata', but changing it affects the API messages.
      expect(page).to have_text("Study metadata data release prevention other comment can't be blank")
    end

    it "creates the study when the prevention 'other' comment is supplied" do
      select 'Other (please specify)', from: 'What is the reason for preventing data release?'
      fill_in 'Please explain the reason for preventing data release', with: 'Some reason'
      fill_in approval_number_field, with: '12345'
      click_button 'Create'

      expect_to_be_on_information_page_for(study_name)
      expect(page).to have_text('Your study has been created')
    end

    it 'creates the study when a prevention reason is selected' do
      select 'Protecting IP - DAC approval required', from: 'What is the reason for preventing data release?'
      fill_in approval_number_field, with: '12345'
      click_button 'Create'

      expect_to_be_on_information_page_for(study_name)
      expect(page).to have_text('Your study has been created')
    end
  end
end
