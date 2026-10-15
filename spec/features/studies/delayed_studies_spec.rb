# frozen_string_literal: true

require 'rails_helper'

# Migrated from features/studies/5528168_delayed_studies_causing_errors.feature
RSpec.describe 'Delayed studies' do
  let(:user) { create(:admin, first_name: 'John', last_name: 'Smith') }
  let!(:study) { create(:study, name: 'Testing delayed studies', state: 'active') }

  before { login_user(user) }

  [3, 6, 9, 12].each do |period|
    it "shows a study delayed for #{period} months without errors" do
      study.update!(
        study_metadata_attributes: {
          data_release_timing: 'delayed',
          data_release_delay_reason: Study::DATA_RELEASE_DELAY_FOR_OTHER,
          data_release_delay_other_comment: "It's not working",
          data_release_delay_period: "#{period} months"
        }
      )

      visit study_information_path(study)
      click_link 'study details'

      expect(page).to have_css('tr', text: /Delay for:\s+#{period} months/)
      expect(page).to have_css('tr', text: /Please explain the reason for delaying release:\s+It's not working/)
    end
  end
end
