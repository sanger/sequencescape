# frozen_string_literal: true

require 'rails_helper'

describe 'Managing study documents', :js do
  let(:user) { create(:admin) }
  let!(:study) { create(:study, name: 'Study testing nil documents') }

  before do
    login_user(user)
    visit study_path(study)
    click_link 'Manage'
  end

  it 'does not create a document when updating without attaching a file' do
    click_button 'Update'

    expect(page).to have_text('Your study has been updated')
    expect(page).to have_no_text('Listing 1 document')
    expect(Document.where(filename: nil)).to be_empty
  end

  it 'attaches the uploaded file without creating documents with nil filenames' do
    attach_file('Attach HMDMC approval', Rails.root.join('test/data/blah.fasta'))
    click_button 'Update'

    expect(page).to have_text('Your study has been updated')
    expect(page).to have_text('Listing 1 document')
    expect(page).to have_text('blah.fasta')
    expect(Document.where(filename: nil)).to be_empty
  end
end
