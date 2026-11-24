# frozen_string_literal: true

require 'rails_helper'

# Migrated from features/plain/5197615_external_release_flag.feature
describe 'External release flag for a lane' do
  let(:user) { create(:admin, login: 'John Smith') }

  before { login_user(user) }

  { nil => 'Unknown', true => 'Yes', false => 'No' }.each do |external_release, displayed|
    it "displays '#{displayed}' when external release is #{external_release.inspect}" do
      lane = create(:lane, external_release:)

      visit receptacle_path(lane)

      within('tr', text: 'Data to be released externally?') { expect(page).to have_text(displayed) }
    end
  end
end
