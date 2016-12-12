# frozen_string_literal: true
require 'rails_helper'
require 'pry'

feature 'Asset submission', js: true do
  let(:user) { create :admin }
  let(:project) { create :project }
  let(:study) { create :study }
  let(:asset) { create :library_tube }
  let(:target_asset) { create :library_tube, name: 'Target asset' }

  scenario 'request additional sequencing' do
    sequencing_types = { 'Illumina-C Single ended sequencing' => 76,
                        'Illumina-C Paired end sequencing' => 76,
                        'Illumina-C HiSeq Paired end sequencing' => 100 }
    sequencing_types.each do |sequencing_type, read_length|
      request_type = RequestType.find_by_name(sequencing_type)
      request = create(:request,
                          study: study,
                          project: project,
                          asset: asset,
                          target_asset: target_asset,
                          request_type: request_type,
                          request_metadata_attributes: {
                            fragment_size_required_to: 1,
                            fragment_size_required_from: 999,
                            library_type: 'Standard',
                            read_length: read_length
                          }
                      )
      login_user user
      visit asset_path(asset)
      click_link 'Request additional sequencing'
      select(sequencing_type, from: "Request type")
      select(study.name, from: "Study")
      select(project.name, from: "Project")
      fill_in "Fragment size required (from)", with: "100"
      fill_in "Fragment size required (to)", with: "200"
      select(read_length, from: "Read length")
      click_button "Create"
      expect(page).to have_content "Created request"
      expect(page).to have_current_path(asset_path(asset))
      Delayed::Worker.new.work_off
      expect(asset.requests.where(request_type_id: request_type.id).count).to equal 2
    end
  end

  def login_user(user)
    visit login_path
    fill_in 'Username', with: user.login
    fill_in 'Password', with: 'password'
    click_button 'Login'
    true
  end
end
