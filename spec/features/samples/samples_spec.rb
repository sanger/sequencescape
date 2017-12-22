# frozen_string_literal: true

require 'rails_helper'

feature 'Sample' do
  let(:user) { create :user, login: 'John Smith' }
  let(:admin) { create :admin }
  let(:sample_manifest) { create :sample_manifest }
  let(:metadata) do
    { cohort: 'cohort_1',
      gender: 'Unknown',
      country_of_origin: 'country_1',
      sample_public_name: 'Public Name',
      sample_taxon_id: '12345' }
  end
  let(:sample) { create :sample, sample_manifest: sample_manifest, sample_metadata: create(:sample_metadata, metadata) }

  context 'standard user' do
    background do
      login_user user
    end

    scenario 'view the manifest that a sample was created from' do
      visit sample_path(sample)
      expect(page).to have_content(sample.name)
      expect(page).to have_content(sample_manifest.name)
      click_link(sample_manifest.name)
      expect(page).to have_content('Download Blank Manifest')
    end

    scenario 'view the sample metadata' do
      visit sample_path(sample)
      expect(page).to have_content(metadata[:cohort])
      expect(page).to have_content(metadata[:gender])
      expect(page).to have_content(metadata[:country_of_origin])
      expect(page).to have_content(metadata[:sample_public_name])
      expect(page).to have_content(metadata[:sample_taxon_id])
    end

    scenario 'standard user cannot edit the sample' do
      visit edit_sample_path(sample)
      expect(page).to have_content(sample.name)
      expect(page).to have_content('Sample details can only be altered by the owner or an administrator or manager')
    end
  end

  context 'administrator user' do
    background do
      login_user admin
    end

    scenario 'view the sample metadata as administrator' do
      visit sample_path(sample)
      expect(page).to have_content(sample.name)
      click_link('Edit')
      expect(page).to have_content("Edit #{sample.name}")
    end
  end
end
