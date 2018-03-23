require 'rails_helper'

feature 'Billing report', js: true, billing: true do
  before do
    Billing.configure do |config|
      config.fields = config.load_file(File.join('spec', 'data', 'billing'), 'fields')
    end
    DownloadHelpers::remove_downloads
  end

  let(:user) { create :user, email: 'login@example.com' }

  feature 'generate BIF file' do
    scenario 'file was generated' do
      login_user user
      visit new_billing_report_path
      expect(page).to have_content 'Billing report (BIF)'
      fill_in('billing_report_start_date', with: '06/04/2017').send_keys(:tab)
      fill_in('billing_report_end_date', with: '10/04/2017').send_keys(:escape)
      click_button 'Generate BIF file'
      expect(DownloadHelpers::downloaded_file('newfile.bif')).to include('')
    end
  end
end
