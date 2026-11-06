# frozen_string_literal: true

require 'rails_helper'
require_relative 'cherrypicking_helpers'

RSpec.describe 'Printing the buffer requirement on cherrypicking worksheets', :js do
  include SlfCherrypickingHelpers

  [false, true].each do |buffer_required|
    it "#{buffer_required ? 'prints' : 'does not print'} Buffer Required for a one-sample destination plate" do
      batch = released_cherrypicking_batch(sample_count: 1, minimum_pick: '1.0')
      destination.wells.each { |well| well.well_attribute.update!(buffer_volume: nil) } unless buffer_required
      # Cucumber seeds this robot for worksheet selection, in addition to myrobot.
      create(:hamilton, name: 'Hamilton STAR 6', barcode: '67')
      visit batch_path(batch)
      expect(page).to have_current_path(batch_path(batch))
      within('#output_assets') { click_button 'Print worksheet' }
      click_link 'Print Hamilton STAR 6 worksheet'
      expect(page).to have_text('Destination plate')
      if buffer_required
        expect(page).to have_text('Buffer Required')
      else
        expect(page).to have_no_text('Buffer Required')
      end
    end
  end
end
