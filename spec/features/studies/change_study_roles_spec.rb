# frozen_string_literal: true

require 'rails_helper'

describe 'Study roles' do
  let(:user) { create :admin }
  let!(:study) { create :study_with_manager, updated_at: 1.year.ago }
  let(:manager) { study.managers.first }

  it 'can be removed', js: true do
    # We had an issue where the timestamp was not updating on study
    # https://github.com/sanger/sequencescape/issues/2942
    # which was user list to not be updated in the UWH
    login_user(user)
    visit study_path(study)
    click_link 'Contacts'
    expect(find('#role_list')).to have_content(manager.login)
    click_button 'Remove'
    expect(find('#role_list')).not_to have_content(manager.login)
    expect(study.reload.updated_at).to be > 1.hour.ago
  end
end
