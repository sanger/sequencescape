# frozen_string_literal: true

require 'rails_helper'

# Migrated from features/plain/5004860_change_decision_by_request.feature
describe 'Changing the decision on a request' do
  let(:user) { create(:admin, login: 'John Doe') }
  let(:reason) { 'User Smith asked to modify this status' }
  let(:new_qc_state) { 'passed' } # A QC state other than the current 'pending'
  let(:request) do
    library_tube = create(:empty_library_tube, qc_state: 'pending')
    library_tube.parents << create(:sample_tube)
    lane = create(:lane, qc_state: 'pending')
    create(:request_with_sequencing_request_type, asset: library_tube, target_asset: lane, state: 'passed')
  end

  before do
    login_user(user)
    visit request_path(request)
    click_link 'Change decision'
  end

  it 'shows the change decision form' do
    expect(page).to have_text('Change decision')
    expect(page).to have_text('Request State')
  end

  it 'requires at least one option to be selected' do
    click_button 'Save changes'
    expect(page).to have_text('Checkboxes at least one must be selected')
  end

  it 'requires a comment to change the request state' do
    check 'Change decision:'
    click_button 'Save changes'
    expect(page).to have_text("Comment can't be blank")
  end

  it 'changes the request state' do
    check 'Change decision:'
    fill_in 'Reason for this action:', with: reason
    click_button 'Save changes'

    expect(page).to have_text('Update. Below you find the new situation.')
    expect(page).to have_text('failed')
    expect(request.reload.state).to eq('failed')
  end

  it 'requires an asset QC state to be selected' do
    check 'Update Asset QC State:'
    click_button 'Save changes'
    expect(page).to have_text("Asset qc state can't be blank")
  end

  it 'does not allow the asset QC state to be set to its current value' do
    check 'Update Asset QC State:'
    select 'pending', from: 'Asset QC State Available'
    fill_in 'Reason for this action:', with: reason
    click_button 'Save changes'
    expect(page).to have_text('Asset qc state cannot be same as current state')
  end

  it 'requires a comment to change the asset QC state' do
    check 'Update Asset QC State:'
    select new_qc_state, from: 'Asset QC State Available'
    click_button 'Save changes'
    expect(page).to have_text("Comment can't be blank")
  end

  it 'changes the asset QC state' do
    check 'Update Asset QC State:'
    select 'failed', from: 'Asset QC State Available'
    fill_in 'Reason for this action:', with: reason
    click_button 'Save changes'

    expect(page).to have_text('Update. Below you find the new situation.')
    expect(page).to have_text('failed')
    expect(request.target_asset.reload.qc_state).to eq('failed')
  end

  it 'changes both the request state and the asset QC state' do
    check 'Change decision:'
    check 'Update Asset QC State:'
    select 'failed', from: 'Asset QC State Available'
    fill_in 'Reason for this action:', with: reason
    click_button 'Save changes'

    expect(page).to have_text('Update. Below you find the new situation.')
    expect(request.reload.state).to eq('failed')
    expect(request.target_asset.reload.qc_state).to eq('failed')
  end
end
