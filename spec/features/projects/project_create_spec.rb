# frozen_string_literal: true

require 'rails_helper'

describe 'Creating projects' do
  let(:user) { create(:admin) }

  before do
    login_user user
  end

  it 'can be started from the homepage' do
    visit root_path
    click_link 'Create Project'

    expect(page).to have_current_path(new_project_path)
  end

  it 'can be started from the projects page' do
    visit projects_path
    click_link 'New Project'

    expect(page).to have_current_path(new_project_path)
  end

  it 'requires the required fields' do
    visit new_project_path

    expect(page).to have_field('Name', type: :text)
    expect(page).to have_field('Project cost code', type: :text)
    expect(page).to have_field('Sequencing Project Manager', type: :select)
    expect(page).to have_field('Sequencing budget division', type: :select)

    click_button 'Create'

    expect(page).to have_current_path(projects_path)
    expect(page).to have_text("Name can't be blank")
    expect(page).to have_text("cost code can't be blank")
  end

  it 'does not show the creation error on subsequent pages' do
    visit new_project_path
    click_button 'Create'

    expect(page).to have_current_path(projects_path)
    expect(page).to have_text('Problems creating your new project')

    click_link 'Projects'

    expect(page).to have_current_path(projects_path)
    expect(page).to have_no_text('Problems creating your new project')
  end

  it 'creates a sequencing project successfully as an admin' do
    visit new_project_path
    expect(page).to have_text('Projects New')

    fill_in 'Name', with: 'Testing project creation'
    fill_in 'Project cost code', with: 'Cost code 101'
    select 'Internal', from: 'Project funding model'
    select 'Unallocated', from: 'Sequencing budget division'
    select 'Unallocated', from: 'Sequencing Project Manager'

    # Sequencing project fields
    fill_in 'Funding comments', with: 'Internal'
    fill_in 'Collaborators', with: 'no collaborators'
    fill_in 'External funding source', with: 'no funding source'
    click_button 'Create'

    project = Project.find_by!(name: 'Testing project creation')
    expect(page).to have_current_path(project_path(project))
    expect(page).to have_text('Your project has been created')
    expect(page).to have_text('Cost code 101')
    expect(page).to have_text('Unallocated')
    expect(page).to have_text('Internal')
    expect(page).to have_text('no collaborators')
    expect(page).to have_text('no funding source')
  end

  context 'when creating a sequencing project as a manager' do
    let(:user) { create(:manager) }

    it 'hides administrator-only fields and creates the project' do
      visit new_project_path
      expect(page).to have_text('Projects New')
      expect(page).to have_no_field('External funding source')
      expect(page).to have_no_field('Sequencing Project Manager')
      expect(page).to have_no_field('Sequencing budget division')
      expect(page).to have_no_field('Sequencing budget cost centre')

      fill_in 'Name', with: 'Manager project'
      fill_in 'Project cost code', with: 'ABC'
      fill_in 'Funding comments', with: 'Internal'
      fill_in 'Collaborators', with: 'no collaborators'
      click_button 'Create'

      project = Project.find_by!(name: 'Manager project')
      expect(page).to have_current_path(project_path(project))
      expect(page).to have_text('Your project has been created')
      expect(page).to have_text('ABC')
      expect(page).to have_text('no collaborators')
    end
  end

  shared_examples 'creates a Microarray genotyping project' do
    it 'creates the project with the tracking ID' do
      visit root_path
      click_link 'Create Project'
      expect(page).to have_text('Projects New')

      fill_in 'Name', with: 'Microarray project'
      fill_in 'Project cost code', with: 'ABC'
      # Genotyping project field
      fill_in 'Genotyping committee Tracking ID', with: '12345'
      click_button 'Create'

      project = Project.find_by!(name: 'Microarray project')
      expect(page).to have_current_path(project_path(project))
      expect(page).to have_text('Your project has been created')
      expect(page).to have_text('12345')
      expect(page).to have_text('ABC')
    end
  end

  context 'when creating a microarray project as an administrator' do
    it_behaves_like 'creates a Microarray genotyping project'
  end

  context 'when creating a microarray project as a manager' do
    let(:user) { create(:manager) }

    it_behaves_like 'creates a Microarray genotyping project'
  end
end
