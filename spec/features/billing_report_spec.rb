require 'rails_helper'

feature 'Billing report', js: true do
  let(:user) { create :user, email: 'login@example.com' }

  feature 'generate BIF file' do

    scenario 'user can pool from different tubes to stock and standard mx tubes' do
      login_user user
      visit new_billing_report_path
      expect(page).to have_content 'Billing report (BIF)'
      fill_in 'billing_report_start_date', with: '06/04/2017'
      fill_in 'billing_report_end_date', with: '10/04/2017'
      find("input[value='Generate BIF file']").trigger('click')
      expect(page).to have_current_path(new_billing_report_path)
    end

  end
end