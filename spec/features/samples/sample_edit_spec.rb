# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Sample edit', :js do
  let(:user) { create(:admin) }
  let(:sample) { create(:sample) }

  before do
    login_user(user)
  end

  describe 'Sample editing fields' do
    before do
      visit edit_sample_path(sample)
    end

    it 'shows all sample metadata fields' do
      [
        'Cohort',
        'Gender',
        'Country of origin',
        'Geographical region',
        'Ethnicity',
        'DNA source',
        'Volume (µl)',
        'Mother',
        'Father',
        'Replicate',
        'Organism',
        'GC content',
        'Sibling',
        'Concentration'
      ].each do |field|
        expect(page).to have_field(field)
      end
    end
  end

  context 'when setting the Taxon ID' do
    before do
      visit edit_sample_path(sample)
      headers = { 'Content-Type' => 'application/json' }
      stub_request(:get, "#{configatron.ena_taxon_lookup_url}any-name/#{common_name}")
        .to_return(headers:, body:, status:)
    end

    let(:body) { [{ taxId: taxon_id, scientificName: scientific_name, submittable: submittable }].to_json }
    let(:status) { :http_ok }

    # Helper to get validation message for a field
    def validation_message(field_label)
      find_field(field_label).native.attribute('validationMessage')
    end

    context 'when the common name is found' do
      let(:common_name) { 'Human' }
      let(:scientific_name) { 'Homo sapiens' }
      let(:taxon_id) { '9606' }
      let(:submittable) { 'true' }

      it 'populates the taxon fields' do
        fill_in 'Common Name', with: common_name
        click_button 'Lookup Taxon from Common Name'

        expect(find_field('Common Name').value).to eq(scientific_name)
        expect(find_field('Taxon ID').value).to eq(taxon_id)
        expect(validation_message('Common Name')).to eq('')
        expect(validation_message('Taxon ID')).to eq('')
      end
    end

    context 'when the common name is found, but is not submittable' do
      let(:common_name) { 'Hominidae' }
      let(:scientific_name) { 'Hominidae' }
      let(:taxon_id) { '9604' }
      let(:submittable) { 'false' }

      it 'taxon fields fail validation' do
        fill_in 'Common Name', with: common_name
        click_button 'Lookup Taxon from Common Name'

        expect(find_field('Common Name').value).to eq(scientific_name)
        expect(find_field('Taxon ID').value).to eq(taxon_id)
        expect(validation_message('Common Name')).to eq('This organism is not submittable.')
        expect(validation_message('Taxon ID')).to eq('This organism is not submittable.')
      end
    end

    context 'when the common name cannot be found' do
      let(:common_name) { 'Supercalifragilisticexpialidocious' }
      let(:body) { [] }

      it 'taxon fields fail validation' do
        fill_in 'Common Name', with: common_name
        click_button 'Lookup Taxon from Common Name'

        expect(find_field('Common Name').value).to eq(common_name)
        expect(find_field('Taxon ID').value).to eq('<not found>')
        expect(validation_message('Common Name')).to eq('')
        expect(validation_message('Taxon ID')).to eq('This organism cannot be found.')
      end
    end
  end

  describe 'editing a sample' do
    context 'when the user is an administrator' do
      let(:user) { create(:admin) }
      let(:sample) { create(:sample) }

      before do
        login_user(user)
        visit sample_path(sample)
      end

      it 'allows the user to open the edit page' do
        click_link 'Edit'

        expect(page).to have_current_path(edit_sample_path(sample))
      end

      context 'when updating the sample' do
        before do
          login_user(user)
          visit edit_sample_path(sample)
        end

        it 'allows the user to update the sample' do
          fill_in 'Public Name', with: 'Updated Sample Name'
          click_button 'Save Sample'

          expect(page).to have_current_path(sample_path(sample))
          expect(page).to have_text('Updated Sample Name')
        end
      end
    end

    context 'when the user is not the owner or an administrator' do
      let(:user) { create(:user) }

      it 'redirects the user to the homepage' do
        login_user(user)
        visit edit_sample_path(sample)

        expect(page).to have_current_path(root_path)
        expect(page).to have_text('Sorry, you are not authorized to update this Sample')
      end
    end
  end
end
