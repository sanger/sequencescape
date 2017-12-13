require 'rails_helper'

feature "Sample" do
  let(:user) { create :user, login: 'John Smith' }
  let(:sample_manifest) { create :sample_manifest }
  let(:sample) { create :sample, sample_manifest: sample_manifest }
  let(:metadata) { {  } }

  background do
    login_user user
  end

  scenario "view the manifest that a sample was created from" do
    visit sample_path(sample)
    expect(page).to have_content(sample.name)
    expect(page).to have_content(sample_manifest.name)
    click_link(sample_manifest.name)
    expect(page).to have_content("Download Blank Manifest")
  end
end

