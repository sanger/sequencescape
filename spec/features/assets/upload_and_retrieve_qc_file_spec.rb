# frozen_string_literal: true

require 'rails_helper'
require 'pry'

describe 'Asset submission', :js do
  let(:plate) { create(:plate) }
  let(:user) { create(:user) }

  it 'upload a qc file' do
    login_user user
    visit asset_path(plate)
    click_on 'QC Files'
    attach_file('New qc file', Rails.root.join('test/data/quant_test_example.csv'))
    click_button 'Upload file'
    expect(page).to have_text 'quant_test_example.csv was uploaded'
  end
end
