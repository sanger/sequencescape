# frozen_string_literal: true

require 'rails_helper'

# Migrated from features/studies/8447221_data_release_help_text.feature
RSpec.describe 'Update the data release fields when creating a study', :js do
  include StudyFormHelper

  let(:user) { create(:user, login: 'user', roles: [create(:role, name: 'manager')]) }

  before do
    create_study_form_reference_data
    enable_ui_study_creation
    login_user(user)
    visit new_study_path
  end

  ['Managed (EGA)', 'Open (ENA)'].each do |release_strategy|
    it "shows the 'Reason for delaying release' label next to the delay drop down for #{release_strategy} (4044305)" do
      choose_data_release_strategy(release_strategy)
      select 'delayed', from: 'How is the data release to be timed?'
      select 'Other (please specify below)', from: 'Reason for delaying release'

      expect(page).to have_css('label', exact_text: 'Reason for delaying release')
      expect(page).to have_field('Please explain the reason for delaying release')
    end
  end

  ['3 months', '12 months'].each do |delay_period|
    it "asks the same questions for a delay of #{delay_period} as for all other delays (4044273)" do
      select 'delayed', from: 'How is the data release to be timed?'
      select 'Other (please specify below)', from: 'Reason for delaying release'
      select delay_period, from: 'Delay for'
      fill_in 'Please explain the reason for delaying release', with: 'some comment'
      fill_in_study_details(name: 'new study', description: 'writing cukes', human_dna: 'Yes')
      choose_data_release_strategy('Open (ENA)')

      click_button 'Create'

      expect_to_be_on_information_page_for('new study')
    end
  end
end
