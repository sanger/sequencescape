# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Following a Sequencing Pipeline', type: :feature, js: true do
  let(:user) { create :user }
  let(:pipeline) { create(:sequencing_pipeline, :with_workflow) }

  let(:spiked_buffer) { create :spiked_buffer, :tube_barcode }

  before do
    asset = create :multiplexed_library_tube, :scanned_into_lab, sample_count: 2
    create_list :sequencing_request_with_assets,
                2,
                request_type: pipeline.request_types.first,
                asset: asset,
                target_asset: nil,
                submission: create(:submission)
  end

  it 'can be processed' do
    login_user(user)
    visit pipeline_path(pipeline)
    within('#available-requests') { all('input[type=checkbox]', count: 2).each(&:check) }
    first(:button, 'Submit').click
    click_on('Specify Dilution Volume')

    all(:field, 'Concentration').each_with_index { |field, index| field.fill_in(with: 1.2 + index) }

    click_on 'Next step'

    fill_in('Barcode', with: spiked_buffer.machine_barcode)

    click_on 'Next step'

    find('#sample-1-checkbox').uncheck

    fill_in('Operator', with: 'James')
    select('XP', from: 'Workflow (Standard or Xp)')
    fill_in('Lane loading concentration (pM)', with: 23)
    fill_in('+4 field of weirdness', with: 'Check stored')

    click_on 'Next step'

    find('#sample-2-checkbox').uncheck

    fill_in('+4 field of weirdness', with: 'Something else')

    click_on 'Next step'

    within '#sample' do
      within(first('li')) do
        expect(page).to have_text('1.2')
        expect(page).to have_text('James')
        expect(page).to have_text('XP')
        expect(page).to have_text('23')
        expect(page).to have_text('Something else')
      end
      within(all('li').last) do
        expect(page).to have_text('2.2')
        expect(page).to have_text('James')
        expect(page).to have_text('XP')
        expect(page).to have_text('23')
        expect(page).to have_text('Check stored')
      end
    end
    click_on 'Release this batch'
    expect(page).to have_content('Batch released')
  end

  context 'when a batch has been created' do
    let(:batch) { create :batch, pipeline: pipeline, requests: pipeline.requests, state: 'released' }

    before do
      batch.requests.each_with_index do |request, i|
        create :lab_event,
               eventful: request,
               batch: batch,
               user: user,
               description: 'Specify Dilution Volume',
               descriptors: {
                 'Concentration' => (1.2 + i).to_s
               }
        create :lab_event,
               eventful: request,
               batch: batch,
               user: user,
               description: 'Set descriptors',
               descriptors: {
                 'Operator' => 'James',
                 'Workflow (Standard or Xp)' => 'XP',
                 'Lane loading concentration (pM)' => '23',
                 '+4 field of weirdness' => 'Something else'
               }
      end
    end

    it 'descriptors can be edited' do
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
    end
  end
end
