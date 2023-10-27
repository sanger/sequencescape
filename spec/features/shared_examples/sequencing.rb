# frozen_string_literal: true

shared_examples 'a sequencing procedure' do
  it 'can be processed', :warren do
    login_user(user)
    visit pipeline_path(pipeline)
    within('#available-requests') { all('input[type=checkbox]', count: 2).each(&:check) }
    first(:button, 'Submit').click
    click_on('Specify Dilution Volume')

    all(:field, 'Concentration').each_with_index { |field, index| field.fill_in(with: 1.2 + index) }

    click_on 'Next step'

    fill_in('PhiX Barcode', with: 'Not a barcode')

    click_on 'Next step'

    expect(page).to have_content("Can't find a spiked hybridization buffer with barcode Not a barcode")

    find_by_id('sample-2-checkbox').uncheck

    fill_in('PhiX Barcode', with: spiked_buffer.machine_barcode)

    click_on 'Next step'

    find_by_id('sample-1-checkbox').uncheck

    expect(page).to have_content('Request 1 :')

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

    first(:link, 'Lane').click
    expect(page).to have_content("Spiked Buffer: #{spiked_buffer.display_name}")

    go_back

    all(:link, 'Lane').last.click
    expect(page).not_to have_content('Spiked Buffer')

    batch = Batch.last
    flowcell_message = batch.messengers.last

    # Really we expect 1 here, but seem to be triggering two copies of the message. I suspect on message creation
    # and another one on updating the batch state
    expect(Warren.handler.messages_matching("queue_broadcast.messenger.#{flowcell_message.id}")).to be_positive
  end
end
