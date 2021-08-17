# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Following a Sequencing Pipeline', type: :feature, js: true do
  let(:user) { create :user }
  let(:pipeline) do
    create(:sequencing_pipeline).tap do |pipeline|
      workflow = pipeline.workflow
      create(:add_spiked_in_control_task, workflow: workflow)
      create(
        :set_descriptors_task,
        workflow: workflow,
        descriptor_attributes: [
          { kind: 'Text', sorter: 2, name: 'Operator' },
          {
            kind: 'Selection',
            sorter: 3,
            name: 'Workflow (Standard or Xp)',
            selection: {
              'Standard' => 'Standard',
              'XP' => 'XP'
            },
            value: 'Standard'
          },
          { kind: 'Text', sorter: 4, name: 'Lane loading concentration (pM)' },
          # We had a bug where the + was being stripped from the beginning of field names
          { kind: 'Text', sorter: 5, name: '+4 field of weirdness' }
        ]
      )
    end
  end

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
    click_on('Add Spiked in control')
    fill_in('Barcode', with: spiked_buffer.machine_barcode)
    click_on 'Next step'

    # We don't currently have labels, so this doesn't work
    fill_in('Operator', with: 'James')
    select('XP', from: 'Workflow (Standard or Xp)')
    fill_in('Lane loading concentration (pM)', with: 23)
    fill_in('+4 field of weirdness', with: 'Check stored')

    click_on 'Next step'

    within '#sample' do
      within(first('li')) do
        expect(page).to have_text('James')
        expect(page).to have_text('XP')
        expect(page).to have_text('23')
        expect(page).to have_text('Check stored')
      end
      within(all('li').last) do
        expect(page).to have_text('James')
        expect(page).to have_text('XP')
        expect(page).to have_text('23')
        expect(page).to have_text('Check stored')
      end
    end
    click_on 'Release this batch'
    expect(page).to have_content('Batch released')
  end
end
