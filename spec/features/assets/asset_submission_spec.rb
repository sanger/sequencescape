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
    request_types = create_list(:sequencing_request_type, 2)
    read_lengths = [76, 108]
    request_types.each_with_index do |request_type, index|
      read_length = read_lengths[index]
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
      select(request_type.name, from: 'Request type')
      select(study.name, from: 'Study')
      select(project.name, from: 'Project')
      fill_in 'Fragment size required (from)', with: '100'
      fill_in 'Fragment size required (to)', with: '200'
      select(read_length, from: 'Read length')
      click_button 'Create'
      expect(page).to have_content 'Created request'
      expect(page).to have_current_path(asset_path(asset))
      Delayed::Worker.new.work_off
      expect(asset.requests.where(request_type_id: request_type.id).count).to equal 2
    end
  end
end
