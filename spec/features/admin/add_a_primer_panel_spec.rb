# frozen_string_literal: true

require 'rails_helper'

describe 'Primer Panel' do
  let(:user) { create(:admin, email: 'login@example.com') }
  let(:primer_panel) { create(:primer_panel, name: 'Primer Panel 1') }

  it 'user can add a new primer panel' do
    login_user user
    click_on 'Admin'
    click_on 'Primer Panel'
    click_on 'New Primer Panel'
    fill_in 'Name', with: 'My Primer panel'
    fill_in 'SNP count', with: 32
    fill_in 'primer_panel_programs_pcr_1_name', with: 'Pcr 1 Name'
    fill_in 'primer_panel_programs_pcr_1_duration', with: '90'
    fill_in 'primer_panel_programs_pcr_2_name', with: 'Pcr 2 Name'
    fill_in 'primer_panel_programs_pcr_2_duration', with: '120'
    click_on 'Create'
    expect(page).to have_content("Created 'My Primer panel'")
  end

  it 'user can edit a primer panel' do
    login_user user
    visit edit_admin_primer_panel_path(primer_panel)
    expect(page).to have_content(
      'Editing a primer panel will affect all experiments where a primer panel has been used.'
    )
    expect(find_field('Name').value).to eq('Primer Panel 1')
    expect(find_field('SNP count').value).to eq('1')
    expect(find_field('primer_panel_programs_pcr_1_name').value).to eq('pcr1 program')
    expect(find_field('primer_panel_programs_pcr_1_duration').value).to eq('45')
    expect(find_field('primer_panel_programs_pcr_2_name').value).to eq('pcr2 program')
    expect(find_field('primer_panel_programs_pcr_2_duration').value).to eq('20')
    click_on 'Update'
    expect(page).to have_content('Primer Panel was successfully updated.')
  end
end
