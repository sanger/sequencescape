# frozen_string_literal: true

require 'rails_helper'

# This test verifies searching functionality across various search options.

RSpec.feature 'Searching sequencescape', :search do
  let(:user) { create(:user, login: 'user') }

  before do
    login_user(user)
    visit searches_path

    create(:project, name: 'This Rabbit')
    create(:project, name: 'Project 2').tap do |project|
      project.project_metadata.update!(project_cost_code: 'This Cost Code')
    end
    create(:study, name: 'This Hedgehog')
    create(:sample_tube, name: 'This Asset', sample_attributes: { name: 'SampleForThis' })
  end

  [
    { search: 'Rabbit', type: 'project', result: 'This Rabbit' },
    { search: 'Hedgehog', type: 'study', result: 'This Hedgehog' },
    { search: 'Sample', type: 'sample', result: 'SampleForThis' },
    { search: 'Asset', type: 'labware', result: 'This Asset' },
    { search: 'This Cost Code', type: 'project', result: 'This Cost Code' }
  ].each do |example|
    scenario "Searching for #{example[:search]}" do
      fill_in 'Search for', with: example[:search]
      click_on 'Go'
      expect(page).to have_current_path(searches_path, ignore_query: true)
      expect(page).to have_content("1 #{example[:type]}")
      expect(page).to have_content(example[:result])
    end
  end

  scenario 'No matching results' do
    fill_in 'Search for', with: 'No way this will ever match anything!'
    click_on 'Go'
    expect(page).to have_current_path(searches_path, ignore_query: true)
    expect(page).to have_content('No results')
  end

  scenario 'Searching for everything' do
    fill_in 'Search for', with: 'This'
    click_on 'Go'
    expect(page).to have_current_path(searches_path, ignore_query: true)

    [
      { section: 'project', section_count: 2, result: 'This Rabbit' },
      { section: 'study',   section_count: 1, result: 'This Hedgehog' },
      { section: 'sample',  section_count: 1, result: 'SampleForThis' },
      { section: 'labware', section_count: 1, result: 'This Asset' },
      { section: 'project', section_count: 2, result: 'Project 2' }
    ].each do |row|
      expect(page).to have_content("#{row[:section_count]} #{row[:section]}")
      expect(page).to have_content(row[:result])
    end
  end
end
