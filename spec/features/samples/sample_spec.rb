# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Sample', :js do
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
      expect(studies_panel).to have_text('Study_PT_7125863')

      # The select box for adding to study should not include the already-linked study
      within(studies_panel) do
        expect(page).to have_no_select('Add to study', with_options: ['Study_PT_7125863'])
      end
    end
  end

  describe 'Sample details' do
    let(:user) { create(:admin) }
    let!(:sample) { create(:sample, name: 'sample_test') }

    before do
      login_user(user)
      visit sample_path(sample)
    end

    it 'shows the manifest that created the sample' do
      sample_manifest = create(:sample_manifest, id: 1)
      sample.update!(sample_manifest:)
      visit sample_path(sample)

      expect(page).to have_link('Manifest_1')
      click_link 'Manifest_1'

      expect(page).to have_text('Manifest 1')
    end

    it 'shows the sample metadata fields' do
      ['Cohort', 'Gender', 'Country of origin', 'Sequencescape Sample ID', 'Public Name', 'Taxon ID',
       'Sample Collection Date'].each do |label|
        expect(page).to have_text(label)
      end
    end
  end
end
