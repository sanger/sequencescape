# frozen_string_literal: true

require 'rails_helper'

# Migrated from features/studies/user_group.feature
RSpec.describe 'Study user group warning' do
  let(:user) { create(:admin, first_name: 'John', last_name: 'Smith') }

  before { login_user(user) }

  context 'with an unmanaged (open) study that has no data access group' do
    let!(:study) do
      create(:study, name: 'Good study', metadata_options: { data_release_strategy: 'open', data_access_group: nil })
    end

    it "doesn't warn about a missing user group on the manage page" do
      visit study_information_path(study)
      click_link 'Manage'

      expect(page).to have_current_path(admin_study_path(study))
      expect(page).to have_no_text('No user group specified for a managed study.')
    end
  end
end
