# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Sample', :js, type: :feature do
  describe 'Sample study association' do
    let(:user) { create(:admin) }
    let!(:study) { create(:study, name: 'Study_PT_7125863') }
    let!(:sample) { create(:sample, name: 'Sample_PT_7125863', studies: [study]) }

    before do
      login_user(user)
      visit sample_path(sample)
    end

    it 'shows the associated study in the Studies box and does not allow re-selection' do
      # Find the Studies panel (parent of H3 tagged Studies)
      studies_panel = find('h3', text: 'Studies').find(:xpath, '..')

      # Check that the study name is listed in the panel
      expect(studies_panel).to have_content('Study_PT_7125863')

      # The select box for adding to study should not include the already-linked study
      within(studies_panel) do
        expect(page).to have_no_select('Add to study', with_options: ['Study_PT_7125863'])
      end
    end
  end
end
