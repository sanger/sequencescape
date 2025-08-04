# frozen_string_literal: true

require 'rails_helper'

describe 'Manage a study' do
  let(:user) { create(:admin) }
  let!(:study) { create(:study, name: 'Original name') }

  it 'Rename a study', :js do
    login_user(user)
    visit study_path(study)
    click_link 'Manage'
    expect(page).to have_content('Original name')
    fill_in 'Study name', with: 'Updated name', fill_options: { clear: :backspace }
    click_on 'Update'
    expect(page).to have_content('Updated name')
    expect(page).to have_no_content('Original name')
  end

  context 'with data release strategy' do
    before do
      login_user user
      visit study_path study
      click_link 'Manage'
    end

    it 'displays HuMFre approval number when Open (ENA) is clicked' do
      choose('Open (ENA)', allow_label_click: true)
      expect(page).to have_field('HuMFre approval number', type: :text)
    end

    it 'displays HuMFre approval number when Managed (EGA) is clicked' do
      choose('Managed (EGA)', allow_label_click: true)
      expect(page).to have_field('HuMFre approval number', type: :text)
    end

    it 'displays HuMFre approval number when Not Applicable is clicked' do
      choose('Not Applicable', allow_label_click: true)
      expect(page).to have_field('HuMFre approval number', type: :text)
    end
  end
end
