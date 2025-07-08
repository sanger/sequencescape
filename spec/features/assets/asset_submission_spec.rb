# frozen_string_literal: true

require 'rails_helper'

describe 'Asset submission', :js do
  let(:project) { create(:project) }
  let(:study) { create(:study) }
  let(:request_factory) { :sequencing_request }
  let(:asset) { create(:library_tube) }
  let(:flowcell_types) { create_list(:flowcell_type, 2) }
  let(:request_types) { create_list(:sequencing_request_type, 2) }
  let(:original_request_type) { request_types.first }
  let(:selected_request_type) { original_request_type }
  let(:selected_read_length) { '76' }
  let(:request_flowcell_type_validator) do
    RequestType::Validator.create(
      request_type: selected_request_type,
      request_option: 'requested_flowcell_type',
      valid_options: flowcell_types.map(&:name)
    )
  end
  let!(:original_request) do
    create(request_factory, study: study, project: project, asset: asset, request_type: selected_request_type)
  end

  describe 'The request form does not set default values' do
    let(:user) { create(:admin) }

    before do
      login_user user
      visit labware_path(asset)
      click_link 'Request additional sequencing'
    end

    describe 'when the form is loaded' do
      it 'does not set request type' do
        expect(page).to have_select('Request type', selected: 'Select a request type')
      end
    end

    describe 'when the user selects a request type' do
      before { select 'Request Type 1', from: 'Request type' }

      it 'does not set flowcell type to default value' do
        expect(page).to have_select('Flowcell type', selected: 'Select a requested flowcell type')
      end

      it 'does not set read length to default value' do
        expect(page).to have_select('Read length', selected: 'Select a read length')
      end
    end
  end

  describe 'Validation of Flowcell Type field for request types that require a Flowcell Type' do
    let(:user) { create(:admin) }

    # Mock the validator for the selected request type to return the predefined flowcell type validator
    # the predefined flowcell type validator require a specific flowcell type to be selected
    before do
      allow(selected_request_type).to receive(:validator_for).with('requested_flowcell_type').and_return(
        request_flowcell_type_validator
      )
      login_user user
      visit labware_path(asset)
      click_link 'Request additional sequencing'
    end

    it 'displays an error if Flowcell Type is not set' do
      select(selected_request_type.name, from: 'Request type')
      select(study.name, from: 'Study')
      select(project.name, from: 'Project')
      fill_in 'Fragment size required (from)', with: '100'
      fill_in 'Fragment size required (to)', with: '200'
      select(selected_read_length, from: 'Read length')
      click_button 'Create'

      # The JS native validation error 'Please select an item in the list' is being displayed but cannot be inspected.
      expect(page).to have_no_text 'Created request'

      redirect_path =
        new_request_receptacle_path(
          asset.receptacle,
          study_id: study.id,
          project_id: project.id,
          request_type_id: selected_request_type.id
        )
      expect(page).to have_current_path(redirect_path)
    end

    it 'creates a new request successfully when Flowcell Type is correctly set' do
      select(selected_request_type.name, from: 'Request type')
      select(study.name, from: 'Study')
      select(project.name, from: 'Project')
      fill_in 'Fragment size required (from)', with: '100'
      fill_in 'Fragment size required (to)', with: '200'
      select(selected_read_length, from: 'Read length')
      select('Flowcell 1', from: 'Flowcell type')
      fill_in 'Fragment size required (from)', with: '100'
      fill_in 'Fragment size required (to)', with: '200'
      select(selected_read_length, from: 'Read length')
      click_button 'Create'

      expect(page).to have_text 'Created request'
    end
  end

  describe 'Validation of Flowcell Type field for request types that do not require a Flowcell Type' do
    let(:user) { create(:admin) }

    before do
      login_user user
      visit labware_path(asset)
      click_link 'Request additional sequencing'
    end

    it 'creates a new request successfully even when Flowcell Type is not specified' do
      select(selected_request_type.name, from: 'Request type')
      select(study.name, from: 'Study')
      select(project.name, from: 'Project')
      fill_in 'Fragment size required (from)', with: '100'
      fill_in 'Fragment size required (to)', with: '200'
      select(selected_read_length, from: 'Read length')
      fill_in 'Fragment size required (from)', with: '100'
      fill_in 'Fragment size required (to)', with: '200'
      select(selected_read_length, from: 'Read length')
      click_button 'Create'

      expect(page).to have_text 'Created request'
    end
  end

  shared_examples 'it allows additional sequencing' do
    it 'request additional sequencing' do
      login_user user
      visit labware_path(asset)
      click_link 'Request additional sequencing'
      select(selected_request_type.name, from: 'Request type')
      select(study.name, from: 'Study')
      select(project.name, from: 'Project')
      fill_in 'Fragment size required (from)', with: '100'
      fill_in 'Fragment size required (to)', with: '200'
      select(selected_read_length, from: 'Read length')
      click_button 'Create'
      expect(page).to have_content 'Created request'
      expect(page).to have_current_path(receptacle_path(asset.receptacle))
      expect { Delayed::Worker.new.work_off }.to change {
        asset.requests_as_source.where(request_type_id: selected_request_type).count
      }.by 1
    end
  end

  shared_examples 'it allows cross study sequencing' do
    it 'request additional sequencing without study' do
      login_user user
      visit labware_path(asset)
      click_link 'Request additional sequencing'
      select(selected_request_type.name, from: 'Request type')
      fill_in 'Fragment size required (from)', with: '100'
      fill_in 'Fragment size required (to)', with: '200'
      select(selected_read_length.to_s, from: 'Read length')
      click_button 'Create'
      expect(page).to have_content 'Created request'
      expect(page).to have_current_path(receptacle_path(asset.receptacle))
      expect { Delayed::Worker.new.work_off }.to change {
        asset.requests_as_source.where(request_type_id: selected_request_type).count
      }.by 1
    end

    it 'request additional sequencing with override study' do
      login_user user
      visit labware_path(asset)
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
      expect(page).to have_current_path(receptacle_path(asset.receptacle))
      expect { Delayed::Worker.new.work_off }.to change {
        asset.requests_as_source.where(request_type_id: selected_request_type).count
      }.by 1
    end
  end

  shared_examples 'it forbids additional sequencing' do
    it 'the link is not visible' do
      login_user user
      visit labware_path(asset)
      expect(page).to have_text("Labware #{asset.name}") # confirm page has loaded
      expect(page).to have_no_text('Request additional sequencing')
    end
  end

  shared_examples 'it shows an error message about study' do
    it 'has error message' do
      login_user user
      visit labware_path(asset)
      click_link 'Request additional sequencing'
      select(selected_request_type.name, from: 'Request type')
      select(study.name, from: 'Study')
      select(project.name, from: 'Project')
      fill_in 'Fragment size required (from)', with: '100'
      fill_in 'Fragment size required (to)', with: '200'
      select(selected_read_length, from: 'Read length')
      click_button 'Create'

      # If an error occurs, the user is redirected to the 'new request' page
      # of the current asset, with parameters included in the URL.
      redirect_path =
        new_request_receptacle_path(
          asset.receptacle,
          study_id: study.id,
          project_id: project.id,
          request_type_id: selected_request_type.id
        )
      expect(page).to have_current_path(redirect_path)

      # The redirected page displays an error message detailing the issue
      # encountered. In this particular case, the study does not have an
      # accession number.
      expect(page).to have_content "#{study.name} and all samples must have accession numbers"
    end
  end

  context 'when an admin' do
    let(:user) { create(:admin) }

    context 'with the original request_type' do
      it_behaves_like 'it allows additional sequencing'
    end

    context 'with a new request_type' do
      let(:selected_request_type) { request_types.last }

      it_behaves_like 'it allows additional sequencing'
    end

    context 'when cross study pooled' do
      let(:asset) { create(:multiplexed_library_tube, aliquots: build_list(:library_aliquot, 2)) }
      let(:study) { asset.aliquots.first.study }
      let(:project) { asset.aliquots.first.project }
      let!(:original_request) do
        create(request_factory, study: nil, project: nil, asset: asset, request_type: original_request_type)
      end
      let(:selected_read_length) { '108' }

      it_behaves_like 'it allows cross study sequencing'
    end
  end

  context 'when a regular user' do
    let(:user) { create(:user) }

    it_behaves_like 'it forbids additional sequencing'
  end

  context 'when study does not have an accession number' do
    # Create a user that is allowed to request additional sequencing.
    let(:user) { create(:admin) }

    # Create a study that requires accessioning, but does not have an accession number.
    let(:study) { create(:open_study, accession_number: nil) }

    it_behaves_like 'it shows an error message about study'
  end
end
