# frozen_string_literal: true

require 'rails_helper'

# Migrated from features/administration/11184645_faculty_sponsor_management.feature
describe 'Manage faculty sponsors' do
  include StudyFormHelper

  let(:admin) { create(:admin) }

  context 'when logged in as an administrator' do
    before { login_user admin }

    it 'adds, updates and deletes a faculty sponsor' do
      visit admin_faculty_sponsors_path
      expect(page).to have_text('Faculty Sponsors')

      click_link 'New Faculty Sponsor'
      fill_in 'Name', with: 'Johnny Smith'
      click_button 'Create'
      expect(page).to have_text('Faculty Sponsor was successfully created')
      expect(page).to have_current_path(admin_faculty_sponsors_path)
      expect(page).to have_text('Johnny Smith')

      click_link 'Edit Johnny Smith'
      fill_in 'Name', with: 'Jane Doe'
      click_button 'Update'
      expect(page).to have_text('Faculty Sponsor was successfully updated')
      expect(page).to have_current_path(admin_faculty_sponsors_path)
      expect(page).to have_text('Jane Doe')
      expect(page).to have_no_text('Johnny Smith')

      click_link 'Delete Jane Doe'
      expect(page).to have_text('Faculty Sponsor was successfully deleted')
      expect(page).to have_no_text('Jane Doe')
    end

    it 'lists the studies associated with a faculty sponsor' do
      create(:faculty_sponsor, name: 'Adam Apple')
      barry = create(:faculty_sponsor, name: 'Barry Ball')
      conor = create(:faculty_sponsor, name: 'Conor Cone')

      visit admin_faculty_sponsors_path
      expect(sponsor_study_counts).to include('Adam Apple' => '0', 'Barry Ball' => '0', 'Conor Cone' => '0')

      create(:study, name: 'Big study', metadata_options: { faculty_sponsor: barry })
      create(:study, name: 'Another Big study', metadata_options: { faculty_sponsor: barry })
      create(:study, name: 'Small study', metadata_options: { faculty_sponsor: conor })

      visit admin_faculty_sponsors_path
      # The study factory also creates a sponsor per study, so only check the sponsors created above
      expect(sponsor_study_counts).to include('Adam Apple' => '0', 'Barry Ball' => '2', 'Conor Cone' => '1')

      click_link 'View Barry Ball'
      study_names = page.all('#study_list tbody tr td:first-child').map(&:text)
      expect(study_names).to contain_exactly('Big study', 'Another Big study')
    end

    it 'allows a new sponsor to be used to create a study' do
      create_study_form_reference_data
      enable_ui_study_creation

      visit new_admin_faculty_sponsor_path
      fill_in 'Name', with: 'John Doe'
      click_button 'Create'
      expect(page).to have_text('Faculty Sponsor was successfully created')

      visit new_study_path
      fill_in_study_details(name: 'Sponsored study', description: 'some description')
      select 'John Doe', from: 'Faculty Sponsor'
      choose_data_release_strategy 'Open (ENA)'
      click_button 'Create'

      expect(page).to have_text('Your study has been created')
      expect(Study.find_by!(name: 'Sponsored study').study_metadata.faculty_sponsor.name).to eq('John Doe')
    end

    it 'updates the faculty sponsor of an existing study' do
      original = create(:faculty_sponsor, name: 'John Doe')
      create(:faculty_sponsor, name: 'Jack Sponsor')
      study = create(:study, name: 'Test study', metadata_options: { faculty_sponsor: original })

      visit edit_study_path(study)
      select 'Jack Sponsor', from: 'Faculty Sponsor'
      click_button 'Save Study'

      expect(page).to have_text('Your study has been updated')
      expect(study.reload.study_metadata.faculty_sponsor.name).to eq('Jack Sponsor')
    end
  end

  # Maps sponsor name => number of studies from the index table
  def sponsor_study_counts
    page
      .all('#faculty_sponsor_list tbody tr')
      .to_h { |row| [row.find('td:nth-child(1)').text, row.find('td:nth-child(2)').text] }
  end

  describe 'authorisation' do
    %w[follower internal lab lab_manager manager owner slf_gel slf_manager].each do |role_name|
      it "does not allow a user with the #{role_name} role to manage faculty sponsors" do
        user = create(:user, :with_role, role_name:)
        login_user user

        visit admin_faculty_sponsors_path

        expect(page).to have_text('Sorry, you are not authorized to index this Faculty sponsor')
      end
    end
  end
end
