# frozen_string_literal: true

require 'rails_helper'

# Migrated from features/studies/5393080_nil_document_details.feature
RSpec.describe 'Managing a study should not attach nil documents', :js do
  let(:user) { create(:admin, first_name: 'John', last_name: 'Smith') }
  let!(:study) { create(:study, name: 'Study testing nil documents', state: 'active') }

  before do
    login_user(user)
    visit study_information_path(study)
    click_link 'Manage'
  end

  it 'does not attach a document when no file is supplied' do
    click_button 'Update'

    expect(page).to have_text('Your study has been updated')
    expect(page).to have_no_text('Listing 1 document')
    expect(Document.where(filename: nil)).to be_empty
  end

  it 'attaches the document when a file is supplied' do
    attach_file('Attach HMDMC approval', Rails.root.join('test/data/blah.fasta'))
    click_button 'Update'

    expect(page).to have_text('Your study has been updated')
    expect(page).to have_text('Listing 1 document')
    expect(page).to have_text('blah.fasta')
    expect(Document.where(filename: nil)).to be_empty
  end
end
