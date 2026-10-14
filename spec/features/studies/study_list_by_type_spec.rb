# frozen_string_literal: true

require 'rails_helper'

# Migrated from features/studies/listing_by_type.feature
RSpec.describe 'Listing studies by type', :js do
  let!(:user) { create(:listing_studies_user, :with_role, role_name: 'internal') }

  before do
    login_user(user)
    visit studies_path
  end

  [
    'Interesting',
    'Followed',
    'Managed & active',
    'Managed & inactive',
    'Pending',
    'Pending ethical approval',
    'Contaminated with human dna',
    'Remove x and autosomes',
    'Active',
    'Inactive',
    'Collaborations'
  ].each do |study_type|
    it "lists the studies of type '#{study_type}'" do
      factory_name = :"study_for_study_list_#{study_type.downcase.gsub(/[^a-z0-9]+/, '_')}"
      create(factory_name, user:)

      click_link study_type

      expect(page).to have_text("Study: #{study_type}")
    end
  end
end
