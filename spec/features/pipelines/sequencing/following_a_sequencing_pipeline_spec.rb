# frozen_string_literal: true

require 'rails_helper'
require './spec/features/shared_examples/sequencing'

RSpec.describe 'Following a Sequencing Pipeline', :js do
  let(:user) { create :user }
  let(:pipeline) { create(:sequencing_pipeline, :with_workflow) }

  let(:spiked_buffer) { create :spiked_buffer, :tube_barcode }
  let(:requests) do
    asset = create :multiplexed_library_tube, :scanned_into_lab, sample_count: 2
    create_list :sequencing_request_with_assets,
                2,
                request_type: pipeline.request_types.first,
                asset:,
                target_asset: nil,
                submission: create(:submission)
  end

  before { requests }

  context 'with no pre-added PhiX' do
    it_behaves_like 'a sequencing procedure'
  end

  context 'with one lane of pre-added PhiX' do
    let(:existing_spiked_buffer) { create :spiked_buffer, :tube_barcode }
    let(:with_phi_x) do
      tube = create :multiplexed_library_tube, :scanned_into_lab, sample_count: 2
      tube.parents << existing_spiked_buffer
      tube
    end
    let(:requests) do
      no_phi_x = create :multiplexed_library_tube, :scanned_into_lab, sample_count: 2
      [
        create(
          :sequencing_request_with_assets,
          request_type: pipeline.request_types.first,
          asset: no_phi_x,
          target_asset: nil,
          submission: create(:submission)
        ),
        create(
          :sequencing_request_with_assets,
          request_type: pipeline.request_types.first,
          asset: with_phi_x,
          target_asset: nil,
          submission: create(:submission)
        )
      ]
    end

    it 'can be processed', :warren do
      login_user(user)
      visit pipeline_path(pipeline)
      within('#available-requests') { all('input[type=checkbox]', count: 2).each(&:check) }
      first(:button, 'Submit').click
      click_on('Specify Dilution Volume')

      all(:field, 'Concentration').each_with_index { |field, index| field.fill_in(with: 1.2 + index) }

      click_on 'Next step'

      expect(page).to have_text("Tube #{with_phi_x.display_name} had PhiX added during library preparation")

      fill_in('PhiX Barcode', with: spiked_buffer.machine_barcode)

      click_on 'Next step'

      find_by_id('sample-1-checkbox').uncheck

      select('XP', from: 'Workflow (Standard or Xp)')
      fill_in('Lane loading concentration (pM)', with: 23)
      fill_in('+4 field of weirdness', with: 'Check stored')

      click_on 'Next step'

      find_by_id('sample-2-checkbox').uncheck

      # Pending question on issue#3225 may be populated with previous value
      fill_in('+4 field of weirdness', with: 'Something else', currently_with: '')

      click_on 'Next step'

      within '#sample' do
        within(first('.batch-summary-events .ss-card')) do
          expect(page).to have_text('1.2')
          expect(page).to have_text(spiked_buffer.human_barcode)
          expect(page).to have_text('Something else')
        end
        within(all('.batch-summary-events .ss-card').last) do
          expect(page).to have_text('2.2')

          expect(page).to have_text('XP')
          expect(page).to have_text('23')
          expect(page).to have_text('Check stored')
        end
      end

      click_on 'Release this batch'
      expect(page).to have_content('Batch released')

      batch = Batch.last
      flowcell_message = batch.messengers.last

      # Really we expect 1 here, but seem to be triggering two copies of the message. I suspect on message creation
      # and another one on updating the batch state
      expect(Warren.handler.messages_matching("queue_broadcast.messenger.#{flowcell_message.id}")).to be_positive
      expect(requests.first.reload.target_asset.spiked_in_buffer).to eq(spiked_buffer)
      expect(requests.last.reload.target_asset.spiked_in_buffer).to eq(existing_spiked_buffer)
    end
  end

  context 'when a batch has been created' do
    let(:batch) { create :batch, pipeline:, requests: pipeline.requests, state: 'released', updated_at: 1.day.ago }

    let!(:flowcell_message) { Messenger.create!(target: batch, template: 'FlowcellIO', root: 'flowcell') }

    before do
      batch.requests.each_with_index do |request, i|
        create :lab_event,
               eventful: request,
               batch:,
               user:,
               description: 'Specify Dilution Volume',
               descriptors: {
                 'Concentration' => (1.2 + i).to_s
               }
        create :lab_event,
               eventful: request,
               batch:,
               user:,
               description: 'Set descriptors',
               descriptors: {
                 'Workflow (Standard or Xp)' => 'XP',
                 'Lane loading concentration (pM)' => '23',
                 '+4 field of weirdness' => "Something else #{i}"
               }
        lane = create(:lane)
        request.update(target_asset: lane)
        lane.labware.parents << spiked_buffer
      end
    end

    it 'descriptors can be edited', :warren do
      Warren.handler.clear_messages

      login_user(user)
      visit pipeline_path(pipeline)
      click_on('Released')
      within('#released') { click_link(batch.id.to_s) }
      click_on('Specify Dilution Volume')
      fill_in('Concentration', currently_with: 1.2, with: 1.5)
      fill_in('Concentration', currently_with: 2.2, with: 3.5)

      click_on 'Update'

      # We expect to be back on the batch page, rather than the next step
      expect(page).to have_content('Process your batch or change its composition')

      click_link 'View summary'

      within '#page-content' do
        within(first('.batch-summary-events .ss-card')) do
          expect(page).to have_text('1.5')
          expect(page).to have_text('XP')
          expect(page).to have_text('23')
          expect(page).to have_text('Something else 0')
        end
        within(all('.batch-summary-events .ss-card').last) do
          expect(page).to have_text('3.5')
          expect(page).to have_text('XP')
          expect(page).to have_text('23')
          expect(page).to have_text('Something else 1')
        end
      end

      expect(Warren.handler.messages_matching("queue_broadcast.messenger.#{flowcell_message.id}")).to eq(1)
      expect(Batch.last.updated_at).to be_today
    end

    it 'multiple descriptors can be edited', :warren do
      Warren.handler.clear_messages

      login_user(user)
      visit pipeline_path(pipeline)
      click_on('Released')
      within('#released') { click_link(batch.id.to_s) }
      click_on('Set descriptors')
      fill_in('+4 field of weirdness', currently_with: 'Something else 0', with: 'Not that')
      fill_in('+4 field of weirdness', currently_with: 'Something else 1', with: 'Or that either')

      click_on 'Update'

      # We expect to be back on the batch page, rather than the next step
      expect(page).to have_content('Process your batch or change its composition')

      click_link 'View summary'

      within '#page-content' do
        within(first('.batch-summary-events .ss-card')) do
          expect(page).to have_text('1.2')

          expect(page).to have_text('XP')
          expect(page).to have_text('23')
          expect(page).to have_text('Not that')
        end
        within(all('.batch-summary-events .ss-card').last) do
          expect(page).to have_text('2.2')

          expect(page).to have_text('XP')
          expect(page).to have_text('23')
          expect(page).to have_text('Or that either')
        end
      end

      expect(Warren.handler.messages_matching("queue_broadcast.messenger.#{flowcell_message.id}")).to eq(1)
      expect(Batch.last.updated_at).to be_today
    end

    it 'spiked PhiX can be edited', :warren do
      Warren.handler.clear_messages

      login_user(user)
      visit pipeline_path(pipeline)
      click_on('Released')
      within('#released') { click_link(batch.id.to_s) }
      new_phix = create(:spiked_buffer, :tube_barcode)
      click_on('Add Spiked in control')
      fill_in('PhiX Barcode', with: new_phix.machine_barcode)

      click_on 'Update'

      # We expect to be back on the batch page, rather than the next step
      expect(page).to have_content('Process your batch or change its composition')

      click_link 'View summary'

      expect(Warren.handler.messages_matching("queue_broadcast.messenger.#{flowcell_message.id}")).to eq(1)
      batch.requests.each { |request| expect(request.target_asset.spiked_in_buffer).to eq(new_phix) }
      expect(Batch.last.updated_at).to be_today
    end

    it 'can have failed items' do
      login_user(user)
      visit batch_path(batch)
      expect(page).to have_content('Fail batch or requests')
      expect(page).not_to have_content('Batches can not be failed when pending')
    end
  end
end
