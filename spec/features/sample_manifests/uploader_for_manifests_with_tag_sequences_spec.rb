# frozen_string_literal: true

require 'rails_helper'

feature 'Sample manifest with tag sequences' do
  before(:all) do
    SampleManifestExcel.configure do |config|
      config.folder = File.join('spec', 'data', 'sample_manifest_excel')
      config.tag_group = 'My Magic Tag Group'
      config.load!
    end
  end

  context 'library tube sample manifest with tag sequences' do
    let!(:user)     { create :admin }
    let(:columns)   { SampleManifestExcel.configuration.columns.tube_library_with_tag_sequences.dup }
    let(:test_file) { 'test_file.xlsx' }

    before(:each) do
      download.save(test_file)
      Delayed::Worker.delay_jobs = false
    end

    context 'valid' do
      let(:download) { build(:test_download, columns: columns) }

      scenario 'upload' do
        login_user(user)
        visit('sample_manifest_upload_with_tag_sequences/new')
        attach_file('File to upload', test_file)
        click_button('Upload manifest')
        expect(page).to have_content('Sample manifest successfully uploaded.')
      end
    end

    context 'invalid' do
      let(:download) { build(:test_download, columns: columns, validation_errors: [:library_type]) }

      scenario 'validation errors' do
        login_user(user)
        visit('sample_manifest_upload_with_tag_sequences/new')
        attach_file('File to upload', test_file)
        click_button('Upload manifest')
        expect(page).to have_content('The following error messages prevented the sample manifest from being uploaded')
      end

      scenario 'no file' do
        login_user(user)
        visit('sample_manifest_upload_with_tag_sequences/new')
        click_button('Upload manifest')
        expect(page).to have_content('No file attached')
      end
    end
  end

  context 'multiplexed tube sample manifest with tag sequences' do
    let!(:user)     { create :admin }
    let(:columns)   { SampleManifestExcel.configuration.columns.tube_multiplexed_library_with_tag_sequences.dup }
    let(:test_file) { 'test_file.xlsx' }
    let(:download) { build(:test_download, columns: columns, manifest_type: 'multiplexed_library') }

    before(:each) do
      download.save(test_file)
      Delayed::Worker.delay_jobs = false
    end

    scenario 'upload and reupload' do
      # upload
      expect(download.worksheet.multiplexed_library_tube.aliquots.count).to eq 0
      login_user(user)
      visit('sample_manifest_upload_with_tag_sequences/new')
      attach_file('File to upload', test_file)
      click_button('Upload manifest')
      expect(page).to have_content('Sample manifest successfully uploaded.')
      expect(download.worksheet.multiplexed_library_tube.aliquots.count).to eq 6

      # change file before reuploading
      # for 2 samples library_type is chenged for a new one
      new_library_type_name = 'New library type'
      LibraryType.create!(name: new_library_type_name)
      download.worksheet.axlsx_worksheet.rows[10].cells[4].value = 'New library type'
      download.worksheet.axlsx_worksheet.rows[11].cells[4].value = 'New library type'
      download.save(test_file)

      # reupload
      expect(download.worksheet.multiplexed_library_tube.aliquots.count).to eq 6
      expect(download.worksheet.multiplexed_library_tube.aliquots.all? { |a| a.library_type == 'My personal library type' }).to be_truthy

      login_user(user)
      visit('sample_manifest_upload_with_tag_sequences/new')
      attach_file('File to upload', test_file)
      click_button('Upload manifest')
      expect(page).to have_content('Sample manifest successfully uploaded.')

      expect(download.worksheet.multiplexed_library_tube.aliquots.reload.count).to eq 6
      expect(download.worksheet.multiplexed_library_tube.aliquots.select { |a| a.library_type == new_library_type_name }.count).to eq 2
    end

    context 'invalid' do
      let(:download) { build(:test_download, columns: columns, manifest_type: 'multiplexed_library', validation_errors: [:library_type, :tags]) }

      scenario 'validation errors' do
        login_user(user)
        visit('sample_manifest_upload_with_tag_sequences/new')
        attach_file('File to upload', test_file)
        click_button('Upload manifest')
        expect(page).to have_content('The following error messages prevented the sample manifest from being uploaded')
        expect(page).to have_content('Same tags AA, TT are used on rows 10, 15.')
      end
    end
  end

  after(:all) do
    SampleManifestExcel.reset!
  end

  after(:each) do
    File.delete(test_file) if File.exist?(test_file)
    Delayed::Worker.delay_jobs = true
  end

  def login_user(user)
    visit login_path
    fill_in 'Username', with: user.login
    fill_in 'Password', with: 'password'
    click_button 'Login'
    true
  end
end
