# frozen_string_literal: true

require 'rails_helper'

describe 'Manage users' do
  let(:user) { create(:admin, email: 'login@example.com') }
  let(:test_user) { create(:user, login: 'john', first_name: 'John', last_name: 'Smith') }
  let(:primer_panel) { create(:primer_panel, name: 'Primer Panel 1') }

  before do
    test_user # is_created
    create(:study, name: 'Study Name', state: 'active')
    create(:project, name: 'Project Name', state: 'active')
    create(:role, name: 'lab_manager')
    create(:role, name: 'manager')
    login_user user
    click_link 'Admin'
    expect(page).to have_text('Administration')
    click_on 'User management'
    expect(page).to have_text('Registered users')
    expect(page).to have_text('john')
    click_on 'Edit user john'
    expect(page).to have_text('Edit Profile John Smith')
  end

  it 'edit a user' do
    fill_in 'First name', with: 'Jack'
    fill_in 'Last name', with: 'Doe'
    click_button 'Update'
    expect(page).to have_text 'Jack Doe'
  end

  it 'grant universal roles' do
    check 'Lab manager'
    click_button 'Update'
    expect(page).to have_text 'John Smith'
    expect(test_user.roles.pluck(:name)).to eq(['lab_manager'])
  end

  it 'assign a study role', :js do
    within('div#study_role') do
      select('manager', from: 'Study role')
      select('Study Name', from: 'for Study')
      click_button 'Add Study role'
    end
    expect(page).to have_text 'Manager'
  end

  it 'assign a project role', :js do
    within('div#project_role') do
      select('manager', from: 'Project role')
      select('Project Name', from: 'for Project')
      click_button 'Add Project role'
    end
    expect(page).to have_text 'Manager'
  end
end
