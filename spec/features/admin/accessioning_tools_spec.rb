# frozen_string_literal: true

require 'rails_helper'

describe 'Accessioning tools', :accessioning_enabled, :js do
  let(:admin) { create(:admin) }

  let(:study) { create(:open_study, accession_number: 'ENA123') }
  let(:samples_today) { create_list(:sample, 3, studies: [study]) }
  let(:samples_last_week) { create_list(:sample, 4, studies: [study]) }

  let(:today) { Date.current }
  let(:last_week) { 1.week.ago.to_date }

  before do
    # rubocop:disable Rails/SkipsModelValidations
    samples_today.each { |s| s.update_column(:updated_at, Time.current) }
    samples_last_week.each { |s| s.update_column(:updated_at, 1.week.ago) }
    # rubocop:enable Rails/SkipsModelValidations

    login_user admin
    visit admin_accessioning_tools_path
    # wait for the page to load
    expect(page).to have_text('Accessioning Tools') # rubocop:disable RSpec/ExpectInHook
  end

  describe 'live preview' do
    it 'shows a preview count for today only' do
      fill_in 'start_date', with: today.strftime('%d/%m/%Y')
      fill_in 'end_date', with: today.strftime('%d/%m/%Y')

      expect(page).to have_css('#bulk-accession-preview', text: '3 sample(s) over 1 studies')
    end

    it 'updates the preview when the date range is extended to include last week' do
      fill_in 'start_date', with: last_week.strftime('%d/%m/%Y')
      fill_in 'end_date', with: today.strftime('%d/%m/%Y')

      expect(page).to have_css('#bulk-accession-preview', text: '7 sample(s) over 1 studies')
    end

    it 'updates the preview when the date range is only the last week' do
      fill_in 'start_date', with: last_week.strftime('%d/%m/%Y')
      fill_in 'end_date', with: last_week.strftime('%d/%m/%Y')

      expect(page).to have_css('#bulk-accession-preview', text: '4 sample(s) over 1 studies')
    end

    it 'shows an error in the preview when an invalid date is entered' do
      fill_in 'start_date', with: ''
      fill_in 'end_date', with: today.strftime('%d/%m/%Y')

      expect(page).to have_css('#bulk-accession-preview', text: /error occurred/)
    end
  end
end
