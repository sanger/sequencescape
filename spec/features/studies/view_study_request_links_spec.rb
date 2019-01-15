# frozen_string_literal: true

require 'rails_helper'

feature 'View study properties' do
  let(:user) { create :admin }
  let(:study) { create(:study, name: 'Study 3871492') }
  let(:sample) { create(:sample, name: 'sample_1-3871492') }
  let(:sequencing_request_type) { create :sequencing_request_type }
  let(:single_request) { create(:sequencing_request, request_type: sequencing_request_type, asset: library_tube, state: 'passed', initial_study: study) }
  let(:library_tube) { create(:library_tube, samples: [sample], study: study) }
  let(:sample_tube) { create(:sample_tube, sample: sample, study: study) }

  background do
    user
    study.samples << sample
    sample_tube
    single_request
    create_list(:sequencing_request, 2, request_type: sequencing_request_type, asset: library_tube, state: 'failed', initial_study: study)
    login_user(user)
    visit study_path(study)
  end

  scenario 'No links to absent requests', js: true do
    click_link sequencing_request_type.name
    expect(page).not_to have_link(title: "#{library_tube.name} started")
  end

  scenario 'Single requests link directly to the request', js: true do
    click_link sequencing_request_type.name
    expect(page).to have_link('1', title: "#{library_tube.name} passed")
    click_link('1', title: "#{library_tube.name} passed")
    expect(page).to have_text("This request for #{sequencing_request_type.name.downcase} is PASSED")
  end

  scenario 'Multiple requests link to the summary', js: true do
    click_link sequencing_request_type.name
    expect(page).to have_link('2', title: "#{library_tube.name} failed")
    click_link('2', title: "#{library_tube.name} failed")
    expect(page).to have_text("#{sequencing_request_type.name} Study 3871492")
  end

  scenario 'Filtering by asset type', js: true do
    click_link 'Assets progress'
    within '#summary' do
      expect(page).to have_text sample_tube.name
      expect(page).to have_text library_tube.name
    end
    select('Library tube', from: 'Filter by')
    expect(page).to have_text 'Currently showing Library tube'
    within '#summary' do
      expect(page).not_to have_text sample_tube.name
      expect(page).to have_text library_tube.name
    end
  end
end
