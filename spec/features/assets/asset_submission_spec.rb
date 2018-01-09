# frozen_string_literal: true

require 'rails_helper'
require 'pry'

feature 'Asset submission', js: true do
  let(:project) { create :project }
  let(:study) { create :study }
  let(:request_factory) { :sequencing_request }
  let(:asset) { create :library_tube }
  let(:target_asset) { create :lane, name: 'Target asset' }

  shared_examples 'it allows additional sequencing' do
    scenario 'request additional sequencing' do
      request_types = create_list(:sequencing_request_type, 2)
      read_lengths = [76, 108]
      request_types.each_with_index do |request_type, index|
        read_length = read_lengths[index]
        request = create(request_factory,
                         study: study,
                         project: project,
                         asset: asset,
                         target_asset: target_asset,
                         request_type: request_type)
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

  shared_examples 'it forbids additional sequencing' do
    scenario 'the link is not visible' do
      login_user user
      visit asset_path(asset)
      expect(page).not_to have_text('Request additional sequencing')
    end
  end

  context 'when an admin' do
    let(:user) { create :admin }
    it_behaves_like 'it allows additional sequencing'
  end

  context 'when a regular user' do
    let(:user) { create :user }
    it_behaves_like 'it forbids additional sequencing'
  end
end
