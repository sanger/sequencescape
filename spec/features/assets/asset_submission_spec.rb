# frozen_string_literal: true

require 'rails_helper'

feature 'Asset submission', js: true do
  let(:project) { create :project }
  let(:study) { create :study }
  let(:request_factory) { :sequencing_request }
  let(:asset) { create :library_tube }
  let(:request_types) { create_list(:sequencing_request_type, 2) }
  let(:original_request_type) { request_types.first }
  let(:selected_request_type) { original_request_type }
  let(:selected_read_length) { 76 }
  let!(:original_request) do
    create(request_factory,
           study: study,
           project: project,
           asset: asset,
           request_type: original_request_type)
  end

  shared_examples 'it allows additional sequencing' do
    scenario 'request additional sequencing' do
      login_user user
      visit asset_path(asset)
      click_link 'Request additional sequencing'
      select(selected_request_type.name, from: 'Request type')
      select(study.name, from: 'Study')
      select(project.name, from: 'Project')
      fill_in 'Fragment size required (from)', with: '100'
      fill_in 'Fragment size required (to)', with: '200'
      select(selected_read_length, from: 'Read length')
      click_button 'Create'
      expect(page).to have_content 'Created request'
      expect(page).to have_current_path(asset_path(asset))
      expect { Delayed::Worker.new.work_off }.to change { asset.requests.where(request_type_id: selected_request_type).count }.by 1
    end
  end

  shared_examples 'it allows cross study sequencing' do
    scenario 'request additional sequencing without study' do
      login_user user
      visit asset_path(asset)
      click_link 'Request additional sequencing'
      select(selected_request_type.name, from: 'Request type')
      fill_in 'Fragment size required (from)', with: '100'
      fill_in 'Fragment size required (to)', with: '200'
      select(selected_read_length, from: 'Read length')
      click_button 'Create'
      expect(page).to have_content 'Created request'
      expect(page).to have_current_path(asset_path(asset))
      expect { Delayed::Worker.new.work_off }.to change { asset.requests.where(request_type_id: selected_request_type).count }.by 1
    end

    scenario 'request additional sequencing with override study' do
      login_user user
      visit asset_path(asset)
      click_link 'Request additional sequencing'
      select(selected_request_type.name, from: 'Request type')
      fill_in 'Fragment size required (from)', with: '100'
      fill_in 'Fragment size required (to)', with: '200'
      uncheck('Cross Study Request')
      uncheck('Cross Project Request')
      select(study.name, from: 'Study')
      select(project.name, from: 'Project')
      select(selected_read_length, from: 'Read length')
      click_button 'Create'
      expect(page).to have_content 'Created request'
      expect(page).to have_current_path(asset_path(asset))
      expect { Delayed::Worker.new.work_off }.to change { asset.requests.where(request_type_id: selected_request_type).count }.by 1
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
    context 'with the original request_type' do
      it_behaves_like 'it allows additional sequencing'
    end
    context 'with a new request_type' do
      let(:selected_request_type) { request_types.last }
      it_behaves_like 'it allows additional sequencing'
    end
    context 'when cross study pooled' do
      let(:asset) { create :multiplexed_library_tube, aliquots: build_list(:library_aliquot, 2) }
      let(:study) { asset.aliquots.first.study }
      let(:project) { asset.aliquots.first.project }
      let!(:original_request) do
        create(request_factory,
               study: nil,
               project: nil,
               asset: asset,
               request_type: original_request_type)
      end
      let(:selected_read_length) { 108 }
      it_behaves_like 'it allows cross study sequencing'
    end
  end

  context 'when a regular user' do
    let(:user) { create :user }
    it_behaves_like 'it forbids additional sequencing'
  end
end
