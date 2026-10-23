# frozen_string_literal: true

require 'rails_helper'

# Migrated from features/administration/26913815_add_bait_library_editor_to_admin_view.feature
describe 'Manage bait libraries' do
  let(:admin) { create(:admin) }

  # The Cucumber suite relied on seeded data, RSpec creates the equivalent records
  let(:agilent) { create(:bait_library_supplier, name: 'Agilent') }
  let(:standard_type) { create(:bait_library_type, name: 'Standard') }
  let(:pipeline_type) { create(:bait_library_type, name: 'Custom - Pipeline') }
  let(:customer_type) { create(:bait_library_type, name: 'Custom - Customer') }

  before do
    create(:bait_library, name: 'Human all exon 50MB', bait_library_supplier: agilent, bait_library_type: standard_type,
                          target_species: 'Human')
    pipeline_type
    customer_type
  end

  context 'when logged in as an administrator' do
    before { login_user admin }

    it 'is linked from the administration page and lists the bait libraries' do
      create(:bait_library, name: 'Mouse all exon', bait_library_supplier: agilent,
                            bait_library_type: standard_type, target_species: 'Mouse')

      visit admin_path
      click_link 'Bait library management'

      expect(page).to have_current_path(admin_bait_libraries_path)
      expect(page).to have_text('Bait Libraries Index')
      expect(page).to have_link('New Bait Library')
      expect(table_rows('#bait_library_list')).to include(
        ['Human all exon 50MB', '', 'Agilent', 'Human', 'Standard', 'Edit',
         'Delete'],
        ['Mouse all exon', '', 'Agilent', 'Mouse', 'Standard', 'Edit',
         'Delete']
      )
    end

    it 'edits a bait library' do
      create(:bait_library, name: 'BaitToEdit', bait_library_supplier: agilent, bait_library_type: standard_type)

      visit admin_bait_libraries_path
      click_link 'Edit BaitToEdit'
      expect(page).to have_text('Bait Library Edit')

      fill_in 'Name', with: 'Dragon all exon'
      select 'Agilent', from: 'Supplier'
      fill_in 'Target species', with: 'Dracos'
      fill_in 'Supplier Identifier', with: ''
      select 'Custom - Pipeline', from: 'Bait library type'
      click_button 'Update'

      expect(page).to have_text('Bait Library was successfully updated.')
      expect(page).to have_current_path(admin_bait_libraries_path)
      expect(page).to have_text('Dragon all exon')
      expect(page).to have_text('Dracos')
      expect(page).to have_text('Custom - Pipeline')
      expect(page).to have_no_text('BaitToEdit')
      expect(BaitLibrary.find_by!(name: 'Dragon all exon').supplier_identifier).to be_nil
    end

    it 'adds and removes a bait library' do
      visit admin_bait_libraries_path
      click_link 'New Bait Library'
      expect(page).to have_text('Bait Library New')

      fill_in 'Name', with: 'Centaur all exon'
      select 'Agilent', from: 'Supplier'
      fill_in 'Target species', with: 'Centaur(Greek)'
      fill_in 'Supplier Identifier', with: '8675309'
      select 'Custom - Customer', from: 'Bait library type'
      click_button 'Create'

      expect(page).to have_text('Bait Library was successfully created.')
      expect(page).to have_text('Centaur all exon')
      expect(page).to have_text('Centaur(Greek)')
      expect(page).to have_text('Custom - Customer')
      expect(page).to have_text('8675309')

      click_link 'Delete Centaur all exon'
      expect(page).to have_text('Bait Library was successfully deleted.')
      expect(page).to have_no_text('Centaur all exon')
    end

    it 'fails cleanly on invalid input' do
      visit admin_bait_libraries_path
      click_link 'New Bait Library'
      fill_in 'Name', with: ''
      click_button 'Create'
      expect(page).to have_text('2 errors prohibited this bait library from being saved')
      expect(page).to have_text("Name can't be blank")
      expect(page).to have_text("Target species can't be blank")

      visit admin_bait_libraries_path
      click_link 'Edit Human all exon 50MB'
      fill_in 'Name', with: ''
      select 'Custom - Pipeline', from: 'Bait library type'
      click_button 'Update'
      expect(page).to have_text('1 error prohibited this bait library from being saved')
      expect(page).to have_text("Name can't be blank")

      visit admin_bait_libraries_path
      expect(page).to have_text('Human all exon 50MB')
      expect(page).to have_no_css('#bait_library_list', text: 'Custom - Pipeline')
    end

    it 'lists the library types and suppliers' do
      visit admin_bait_libraries_path

      expect(page).to have_text('Bait Library Types Index')
      expect(page).to have_text('Bait Library Suppliers Index')
      expect(table_rows('#bait_library_supplier_list')).to include(%w[Agilent Edit Delete])
      expect(table_rows('#bait_library_types_list')).to include(
        %w[Standard Edit Delete],
        ['Custom - Pipeline', 'Edit', 'Delete'],
        ['Custom - Customer', 'Edit', 'Delete']
      )
    end

    it 'edits, creates and deletes suppliers' do
      create(:bait_library_supplier, name: 'SupplierToEdit')

      visit admin_bait_libraries_path
      click_link 'Edit SupplierToEdit'
      expect(page).to have_text('Bait Library Supplier Edit')
      fill_in 'Name', with: 'Other Supplier'
      click_button 'Update'
      expect(page).to have_text('Supplier was successfully updated.')
      expect(page).to have_text('Other Supplier')
      expect(page).to have_no_text('SupplierToEdit')

      click_link 'New Bait Library Supplier'
      expect(page).to have_text('Bait Library Supplier New')
      fill_in 'Name', with: 'New Supplier'
      click_button 'Create'
      expect(page).to have_text('Supplier was successfully created.')
      expect(page).to have_text('New Supplier')

      click_link 'Delete New Supplier'
      expect(page).to have_text('Supplier was successfully deleted.')
      expect(page).to have_no_text('New Supplier')
    end

    it 'edits, creates and deletes library types' do
      create(:bait_library_type, name: 'BLTToEdit')

      visit admin_bait_libraries_path
      click_link 'Edit BLTToEdit'
      expect(page).to have_text('Bait Library Type Edit')
      fill_in 'Name', with: 'Normal'
      click_button 'Update'
      expect(page).to have_text('Bait Library Type was successfully updated.')
      expect(page).to have_text('Normal')
      expect(page).to have_no_text('BLTToEdit')

      click_link 'New Bait Library Type'
      expect(page).to have_text('Bait Library Type New')
      fill_in 'Name', with: 'Rare'
      click_button 'Create'
      expect(page).to have_text('Bait Library Type was successfully created.')
      expect(page).to have_text('Rare')

      click_link 'Delete Rare'
      expect(page).to have_text('Bait Library Type was successfully deleted.')
      expect(page).to have_no_text('Rare')
    end

    it "hides, rather than deletes, bait libraries, types and suppliers when they are 'deleted'" do
      create(:bait_library, name: 'Delete This')
      create(:bait_library_type, name: 'Defunct Type')
      create(:bait_library_supplier, name: 'Gone Bankrupt Inc.')

      visit admin_bait_libraries_path
      click_link 'Delete Delete This'
      click_link 'Delete Defunct Type'
      click_link 'Delete Gone Bankrupt Inc.'

      expect(page).to have_no_text('Delete This')
      expect(page).to have_no_text('Defunct Type')
      expect(page).to have_no_text('Gone Bankrupt Inc.')
      expect(BaitLibrary.find_by(name: 'Delete This')).to be_present
      expect(BaitLibraryType.find_by(name: 'Defunct Type')).to be_present
      expect(BaitLibrary::Supplier.find_by(name: 'Gone Bankrupt Inc.')).to be_present

      click_link 'Edit Human all exon 50MB'
      expect(page).to have_no_text('Defunct Type')
      expect(page).to have_no_text('Gone Bankrupt Inc.')
      expect(page).to have_text('Custom - Customer')
    end

    it 'does not allow deleting bait library types or suppliers that are in use' do
      create(:bait_library, name: 'Dragon all exon',
                            bait_library_type: create(:bait_library_type, name: 'Active Type'),
                            bait_library_supplier: create(:bait_library_supplier, name: 'Gone Bankrupt Inc.'))

      visit admin_bait_libraries_path
      click_link 'Delete Active Type'
      expect(page).to have_css(
        '#message_error',
        text: "Can not delete 'Active Type', bait library type is in use by 1 libraries."
      )
      expect(page).to have_css('#bait_library_types_list', text: 'Active Type')

      click_link 'Delete Gone Bankrupt Inc.'
      expect(page).to have_css(
        '#message_error',
        text: "Can not delete 'Gone Bankrupt Inc.', supplier is in use by 1 libraries."
      )
      expect(page).to have_text('Gone Bankrupt Inc.')
    end

    it 'does not offer inactive bait libraries when creating a submission', :js do
      create(:isc_library_and_sequencing_template, name: 'Pulldown ISC - HiSeq Paired end sequencing')
      create(:bait_library, name: 'Delete This').hide

      visit new_submission_path
      select 'Pulldown ISC - HiSeq Paired end sequencing', from: 'submission_template_id'

      expect(page).to have_select('Bait library', with_options: ['Human all exon 50MB'])
      expect(page).to have_no_select('Bait library', with_options: ['Delete This'])
    end
  end

  context 'when logged in as a non-administrator' do
    it 'does not show the bait library editor' do
      login_user create(:user)

      visit admin_bait_libraries_path

      expect(page).to have_text('Sorry, you are not authorized')
      expect(page).to have_no_text('Bait Libraries Index')
    end
  end

  # Returns the text of each cell, for each body row of the table matching the selector
  def table_rows(selector)
    page.all("#{selector} tbody tr").map { |row| row.all('td').map(&:text) }
  end
end
