require 'rails_helper'

feature 'Billing report', js: true, billing: true do
  before do
    Billing.configure do |config|
      config.fields = config.load_file(File.join('spec', 'data', 'billing'), 'fields')
    end
  end

  let(:user) { create :user, email: 'login@example.com' }

  feature 'generate BIF file' do
    scenario 'file was generated' do
      login_user user
      visit new_billing_report_path
      expect(page).to have_content 'Billing report (BIF)'
      fill_in 'billing_report_start_date', with: '06/04/2017'
      fill_in 'billing_report_end_date', with: '10/04/2017'
      find("input[value='Generate BIF file']").trigger('click')
      # if I test that element is not there, it gives me false positive when page has not been fully loaded
      expect { page.find('div#message_error') }.to raise_error(Capybara::ElementNotFound)
    end
  end
end
