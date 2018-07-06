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
      context 'standard' do
        let(:download) { build(:test_download_tubes, columns: columns) }

        scenario 'upload' do
          login_user(user)
          visit('sample_manifest_upload_with_tag_sequences/new')
          attach_file('File to upload', test_file)
          click_button('Upload manifest')
          expect(page).to have_content('Sample manifest successfully uploaded.')
        end

        scenario 'reupload and override' do
          login_user(user)
          visit('sample_manifest_upload_with_tag_sequences/new')
          attach_file('File to upload', test_file)
          click_button('Upload manifest')
          expect(page).to have_content('Sample manifest successfully uploaded.')

          # modify the upload file
          download.worksheet.axlsx_worksheet.rows[10].cells[12].value = 'Female'
          download.save(test_file)

          # re-upload without override set - should be no change
          # login_user(user)
          visit('/sample_manifest_upload_with_tag_sequences/new')
          attach_file('File to upload', test_file)
          click_button('Upload manifest')
          s1 = Sample.find_by(sanger_sample_id: download.worksheet.axlsx_worksheet.rows[10].cells[1].value)
          visit("/samples/#{s1.id}")
          expect(page).to have_content("Sequencescape Sample ID: #{s1.id}")
          expect(page).to have_content('Gender: Unknown')

          # re-upload with override set - should see change to sample
          # login_user(user)
          visit('/sample_manifest_upload_with_tag_sequences/new')
          attach_file('File to upload', test_file)
          check('Override previously uploaded samples')
          click_button('Upload manifest')
          visit("/samples/#{s1.id}")
          expect(page).to have_content("Sequencescape Sample ID: #{s1.id}")
          expect(page).to have_content('Gender: Female')
        end
      end

      context 'cgap foreign barcodes' do
        let(:download) { build(:test_download_tubes_cgap, columns: columns) }

        scenario 'upload' do
          login_user(user)
          visit('sample_manifest_upload_with_tag_sequences/new')
          attach_file('File to upload', test_file)
          click_button('Upload manifest')
          expect(page).to have_content('Sample manifest successfully uploaded.')
        end
      end
    end

    context 'invalid' do
      context 'upload' do
        let(:download) { build(:test_download_tubes, columns: columns, validation_errors: [:library_type]) }

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

      context 'cgap foreign barcodes' do
        let(:download) { build(:test_download_tubes_cgap, columns: columns, validation_errors: [:library_type]) }

        scenario 'validation errors' do
          login_user(user)
          visit('sample_manifest_upload_with_tag_sequences/new')
          attach_file('File to upload', test_file)
          click_button('Upload manifest')
          expect(page).to have_content('The following error messages prevented the sample manifest from being uploaded')
        end
      end

      context 'duplicate cgap foreign barcodes' do
        let(:download) { build(:test_download_tubes_cgap, columns: columns, validation_errors: [:sample_tube_id_duplicates]) }

        scenario 'validation errors' do
          login_user(user)
          visit('sample_manifest_upload_with_tag_sequences/new')
          attach_file('File to upload', test_file)
          click_button('Upload manifest')
          expect(page).to have_content('The following error messages prevented the sample manifest from being uploaded')
        end
      end
    end
  end

  context 'multiplexed tube sample manifest with tag sequences' do
    let!(:user)     { create :admin }
    let(:columns)   { SampleManifestExcel.configuration.columns.tube_multiplexed_library_with_tag_sequences.dup }
    let(:test_file) { 'test_file.xlsx' }

    before(:each) do
      download.save(test_file)
      Delayed::Worker.delay_jobs = false
    end

    context 'valid' do
      context 'upload and reupload' do
        let(:download) { build(:test_download_tubes, columns: columns, manifest_type: 'tube_multiplexed_library_with_tag_sequences') }

        scenario 'with override' do
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
          check('Override previously uploaded samples')
          click_button('Upload manifest')
          expect(page).to have_content('Sample manifest successfully uploaded.')

          expect(download.worksheet.multiplexed_library_tube.aliquots.reload.count).to eq 6
          expect(download.worksheet.multiplexed_library_tube.aliquots.select { |a| a.library_type == new_library_type_name }.count).to eq 2
        end
      end

      context 'cgap foreign barcodes' do
        let(:download) { build(:test_download_tubes_cgap, columns: columns, manifest_type: 'tube_multiplexed_library_with_tag_sequences') }

        scenario 'upload' do
          login_user(user)
          visit('sample_manifest_upload_with_tag_sequences/new')
          attach_file('File to upload', test_file)
          click_button('Upload manifest')
          expect(page).to have_content('Sample manifest successfully uploaded.')
        end
      end
    end

    context 'invalid' do
      context 'upload' do
        let(:download) { build(:test_download_tubes, columns: columns, manifest_type: 'tube_multiplexed_library_with_tag_sequences', validation_errors: %i[library_type tags]) }

        scenario 'validation errors' do
          login_user(user)
          visit('sample_manifest_upload_with_tag_sequences/new')
          attach_file('File to upload', test_file)
          click_button('Upload manifest')
          expect(page).to have_content('The following error messages prevented the sample manifest from being uploaded')
          expect(page).to have_content('Same tags AA, TT are used on rows 10, 15.')
        end

        scenario 'no file' do
          login_user(user)
          visit('sample_manifest_upload_with_tag_sequences/new')
          click_button('Upload manifest')
          expect(page).to have_content('No file attached')
        end
      end

      context 'with cgap barcodes' do
        let(:download) { build(:test_download_tubes_cgap, columns: columns, manifest_type: 'tube_multiplexed_library_with_tag_sequences', validation_errors: [:library_type]) }

        scenario 'validation errors' do
          login_user(user)
          visit('sample_manifest_upload_with_tag_sequences/new')
          attach_file('File to upload', test_file)
          click_button('Upload manifest')
          expect(page).to have_content('The following error messages prevented the sample manifest from being uploaded')
        end
      end

      context 'with cgap barcodes' do
        let(:download) { build(:test_download_tubes_cgap, columns: columns, manifest_type: 'tube_multiplexed_library_with_tag_sequences', validation_errors: [:sample_tube_id_duplicates]) }

        scenario 'duplicates' do
          login_user(user)
          visit('sample_manifest_upload_with_tag_sequences/new')
          attach_file('File to upload', test_file)
          click_button('Upload manifest')
          expect(page).to have_content('The following error messages prevented the sample manifest from being uploaded')
        end
      end
    end
  end

  context 'multiplexed tube sample manifest with tag groups and indexes' do
    let!(:user)     { create :admin }
    let(:columns)   { SampleManifestExcel.configuration.columns.tube_multiplexed_library.dup }
    let(:test_file) { 'test_file.xlsx' }

    before(:each) do
      download.save(test_file)
      Delayed::Worker.delay_jobs = false
    end

    context 'valid' do
      context 'upload and reupload' do
        let(:download) { build(:test_download_tubes, columns: columns, manifest_type: 'tube_multiplexed_library') }

        scenario 'with override' do
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
          download.worksheet.axlsx_worksheet.rows[10].cells[6].value = 'New library type'
          download.worksheet.axlsx_worksheet.rows[11].cells[6].value = 'New library type'
          download.save(test_file)

          # reupload
          expect(download.worksheet.multiplexed_library_tube.aliquots.count).to eq 6
          expect(download.worksheet.multiplexed_library_tube.aliquots.all? { |a| a.library_type == 'My personal library type' }).to be_truthy

          login_user(user)
          visit('sample_manifest_upload_with_tag_sequences/new')
          attach_file('File to upload', test_file)
          check('Override previously uploaded samples')
          click_button('Upload manifest')
          expect(page).to have_content('Sample manifest successfully uploaded.')

          expect(download.worksheet.multiplexed_library_tube.aliquots.reload.count).to eq 6
          expect(download.worksheet.multiplexed_library_tube.aliquots.select { |a| a.library_type == new_library_type_name }.count).to eq 2
        end
      end

      context 'cgap foreign barcodes' do
        let(:download) { build(:test_download_tubes_cgap, columns: columns, manifest_type: 'tube_multiplexed_library') }

        scenario 'upload' do
          login_user(user)
          visit('sample_manifest_upload_with_tag_sequences/new')
          attach_file('File to upload', test_file)
          click_button('Upload manifest')
          expect(page).to have_content('Sample manifest successfully uploaded.')
        end
      end
    end

    context 'invalid' do
      context 'upload' do
        let(:download) { build(:test_download_tubes, columns: columns, manifest_type: 'tube_multiplexed_library', validation_errors: %i[library_type tags]) }

        scenario 'validation errors' do
          login_user(user)
          visit('sample_manifest_upload_with_tag_sequences/new')
          attach_file('File to upload', test_file)
          click_button('Upload manifest')
          expect(page).to have_content('The following error messages prevented the sample manifest from being uploaded')
          expect(page).to have_content('Row 10 - could not find My personal library type library type.')
          expect(page.text).to match(/Tags clash Same tags [A-Z]+, [A-Z]+ are used on rows 10, 15./)
        end

        scenario 'no file' do
          login_user(user)
          visit('sample_manifest_upload_with_tag_sequences/new')
          click_button('Upload manifest')
          expect(page).to have_content('No file attached')
        end
      end

      context 'with cgap barcodes' do
        let(:download) { build(:test_download_tubes_cgap, columns: columns, manifest_type: 'tube_multiplexed_library', validation_errors: [:library_type]) }

        scenario 'validation errors' do
          login_user(user)
          visit('sample_manifest_upload_with_tag_sequences/new')
          attach_file('File to upload', test_file)
          click_button('Upload manifest')
          expect(page).to have_content('The following error messages prevented the sample manifest from being uploaded')
        end
      end

      context 'with cgap barcodes' do
        let(:download) { build(:test_download_tubes_cgap, columns: columns, manifest_type: 'tube_multiplexed_library', validation_errors: [:sample_tube_id_duplicates]) }

        scenario 'duplicates' do
          login_user(user)
          visit('sample_manifest_upload_with_tag_sequences/new')
          attach_file('File to upload', test_file)
          click_button('Upload manifest')
          expect(page).to have_content('The following error messages prevented the sample manifest from being uploaded')
        end
      end
    end
  end

  context 'plate sample manifest' do
    let!(:user)     { create :admin }
    let(:columns)   { SampleManifestExcel.configuration.columns.plate_default.dup }
    let(:test_file) { 'test_file.xlsx' }

    before(:each) do
      download.save(test_file)
      Delayed::Worker.delay_jobs = false
    end

    context 'valid' do
      context 'standard' do
        let(:download) { build(:test_download_plates, columns: columns) }

        scenario 'upload' do
          login_user(user)
          visit('sample_manifest_upload_with_tag_sequences/new')
          attach_file('File to upload', test_file)
          click_button('Upload manifest')
          expect(page).to have_content('Sample manifest successfully uploaded.')
        end
      end

      context 'partial' do
        let(:download) { build(:test_download_plates_partial, columns: columns) }

        scenario 'upload' do
          login_user(user)
          visit('sample_manifest_upload_with_tag_sequences/new')
          attach_file('File to upload', test_file)
          click_button('Upload manifest')
          expect(page).to have_content('Sample manifest successfully uploaded.')
        end
      end

      context 'cgap foreign barcodes' do
        let(:download) { build(:test_download_plates_cgap, columns: columns) }

        scenario 'upload' do
          login_user(user)
          visit('sample_manifest_upload_with_tag_sequences/new')
          attach_file('File to upload', test_file)
          click_button('Upload manifest')
          expect(page).to have_content('Sample manifest successfully uploaded.')
        end
      end

      context 'cgap foreign barcodes partial' do
        let(:download) { build(:test_download_plates_partial_cgap, columns: columns) }

        scenario 'upload' do
          login_user(user)
          visit('sample_manifest_upload_with_tag_sequences/new')
          attach_file('File to upload', test_file)
          click_button('Upload manifest')
          expect(page).to have_content('Sample manifest successfully uploaded.')
        end
      end
    end

    context 'invalid' do
      context 'no file' do
        let(:download) { build(:test_download_plates, columns: columns) }

        scenario 'no file' do
          login_user(user)
          visit('sample_manifest_upload_with_tag_sequences/new')
          click_button('Upload manifest')
          expect(page).to have_content('No file attached')
        end
      end

      context 'unrecognised cgap foreign barcodes' do
        let(:download) { build(:test_download_plates_cgap, columns: columns, validation_errors: [:sample_plate_id_unrecognised_foreign]) }

        scenario 'validation errors' do
          login_user(user)
          visit('sample_manifest_upload_with_tag_sequences/new')
          attach_file('File to upload', test_file)
          click_button('Upload manifest')
          expect(page).to have_content('The following error messages prevented the sample manifest from being uploaded')
        end
      end

      context 'duplicate cgap foreign barcodes' do
        let(:download) { build(:test_download_plates_cgap, columns: columns, validation_errors: [:sample_plate_id_duplicates]) }

        scenario 'validation errors' do
          login_user(user)
          visit('sample_manifest_upload_with_tag_sequences/new')
          attach_file('File to upload', test_file)
          click_button('Upload manifest')
          expect(page).to have_content('The following error messages prevented the sample manifest from being uploaded')
        end
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
