# frozen_string_literal: true

require 'rails_helper'

# Migrated from features/plain/5413994_request_editing_using_legacy_properties.feature
describe 'Editing a request as an administrator' do
  let(:user) { create(:admin, login: 'John Smith') }
  let(:study) { create(:study, name: 'Testing editing a request') }
  let(:library_tube) { create(:empty_library_tube, name: 'tube_1') }
  let(:library_type) { create(:library_type, name: 'Standard') }
  let!(:request) do
    create(:library_creation_request_type, :with_library_types, library_type:).create!(
      asset: library_tube,
      study: study,
      request_metadata_attributes: {
        fragment_size_required_from: 111,
        fragment_size_required_to: 222,
        library_type: 'Standard'
      }
    )
  end

  it 'updates the request details' do
    login_user(user)
    visit edit_request_path(request)

    select 'Standard', from: 'Library type'
    fill_in 'Fragment size required (from)', with: '11111111'
    fill_in 'Fragment size required (to)', with: '22222222'
    fill_in 'Read length', with: '76'
    fill_in 'Gigabases expected', with: '1'
    click_button 'Save Request'

    expect(page).to have_text('Request details have been updated')
    request_information = page.all('.property_group_general tr').to_h { |row| row.all('td').map(&:text) }
    expect(request_information).to eq(
      'Still charge on fail:' => 'Not specified',
      'Read length:' => '76',
      'Gigabases expected:' => '1.0',
      'Fragment size required (from):' => '11111111',
      'Fragment size required (to):' => '22222222',
      'Library type:' => 'Standard'
    )
  end
end
