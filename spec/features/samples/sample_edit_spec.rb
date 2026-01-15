# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Sample accession errors', :js, type: :feature do
  let(:user) { create(:admin) }
  let(:sample) { create(:sample) }

  before do
    login_user(user)
    visit edit_sample_path(sample)
  end

  context 'when setting the Taxon ID' do
    let(:body) { [{ taxId: taxon_id, scientificName: scientific_name, submittable: submittable }].to_json }
    let(:status) { :http_ok }

    before do
      headers = { 'Content-Type' => 'application/json' }
      stub_request(:get, "#{configatron.ena_taxon_lookup_url}any-name/#{common_name}")
        .to_return(headers:, body:, status:)
    end

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
end
