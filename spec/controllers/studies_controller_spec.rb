# frozen_string_literal: true

require 'rails_helper'

RSpec.describe StudiesController do
  let(:data_release_study_type) { create(:data_release_study_type, name: 'genomic sequencing') }
  let(:reference_genome) { create(:reference_genome) }
  let(:study) { create(:study) }
  let(:program) { create(:program) }
  let(:user) { create(:owner) }

  let(:params) do
    {
      'study' => {
        'name' => 'hello',
        'reference_genome_id' => reference_genome.id,
        'study_metadata_attributes' => {
          'faculty_sponsor_id' => create(:faculty_sponsor, name: 'Me'),
          'study_description' => 'some new study',
          'program_id' => program.id,
          'contains_human_dna' => 'No',
          'contaminated_human_dna' => 'No',
          'commercially_available' => 'No',
          'data_release_study_type_id' => data_release_study_type,
          'data_release_strategy' => 'open',
          'study_type_id' => StudyType.find_or_create_by(name: 'Not specified').id,
          'ebi_library_strategy' => 'WGS',
          'ebi_library_source' => 'GENOMIC',
          'ebi_library_selection' => 'PCR',
        }
      }
    }
  end

  before { session[:user] = user.id }

  it_behaves_like 'it requires login'

  describe '#new' do
    before { get :new }

    it 'works', :aggregate_failures do # rubocop:todo RSpec/ExampleWording
      expect(subject).to respond_with :success
      expect(subject).to render_template :new
    end
  end

  describe '#create' do
    before do
      @study_count = Study.count
      post :create, params:
    end

    context 'with valid options' do
      it 'works', :aggregate_failures do # rubocop:todo RSpec/ExampleWording
        expect(subject).to set_flash.to('Your study has been created')
        expect(subject).to redirect_to('study path') { study_path(Study.last) }
      end

      it 'changes Study.count by 1' do
        expect(Study.count - @study_count).to eq(1)
      end
    end

    context 'with invalid options' do
      before do
        @initial_study_count = Study.count
        post :create, params: { 'study' => { 'name' => 'hello 2' } }
      end

      let(:params) { { 'study' => { 'name' => 'hello 2' } } }

      specify(:aggregate_failures) do
        expect(subject).to render_template :new
        expect(subject).to set_flash.now.to('Problems creating your new study')
      end

      it 'not change Study.count' do
        expect(Study.count).to eq(@initial_study_count)
      end
    end

    context 'with poly_metadata options' do
      let(:option_key) { 'scrna_core_pbmc_donor_pooling_required_number_of_cells' }
      let(:option_value) { '1000' }
      let(:params) do
        # Extend parent context's params with poly_metadata options.
        super().merge('poly_metadata' => { option_key => option_value })
      end

      context 'with specified value' do
        it 'creates poly_metadatum with the value' do
          poly_metadatum = Study.last.poly_metadatum_by_key(option_key)
          expect(poly_metadatum.value).to eq(option_value)
        end
      end

      context 'with empty value' do
        let(:option_value) { '' } # Override parent context's option_value.

        it 'does not create poly_metadatum' do
          poly_metadatum = Study.last.poly_metadatum_by_key(option_key)
          expect(poly_metadatum).to be_nil
        end
      end
    end
  end

  describe '#update' do
    context 'with poly_metadata options' do
      let(:option_key) { 'scrna_core_pbmc_donor_pooling_required_number_of_cells' }
      let(:option_value) { '1000' }

      let!(:study) do
        # Create a study without poly_metadata options.
        post(:create, params:)
        Study.last
      end

      let(:update_params) { params.merge('id' => study.id).merge('poly_metadata' => { option_key => option_value }) }

      context 'without existing poly_metadatum' do
        context 'with specified value' do
          it 'creates poly_metadatum with the value' do
            # Existing
            poly_metadatum = study.poly_metadatum_by_key(option_key)
            expect(poly_metadatum).to be_nil

            post :update, params: update_params
            study.reload

            # Updated
            poly_metadatum = study.poly_metadatum_by_key(option_key)
            expect(poly_metadatum).not_to be_nil
            expect(poly_metadatum.value).to eq(option_value)
          end
        end

        context 'with empty value' do
          let(:option_value) { '' }

          it 'does not create poly_metadatum' do
            # Existing
            poly_metadatum = study.poly_metadatum_by_key(option_key)
            expect(poly_metadatum).to be_nil

            post :update, params: update_params
            study.reload

            # Updated
            poly_metadatum = study.poly_metadatum_by_key(option_key)
            expect(poly_metadatum).to be_nil
          end
        end
      end

      context 'with existing poly_metadatum' do
        let(:new_option_value) { '2000' }
        let(:new_update_params) do
          params.merge('poly_metadata' => { option_key => new_option_value }).merge('id' => study.id)
        end

        before do
          post :update, params: update_params # Update once
          study.reload
        end

        context 'with specified value' do
          it 'creates poly_metadatum with the value' do
            # Existing
            poly_metadatum_existing = study.poly_metadatum_by_key(option_key)
            expect(poly_metadatum_existing).not_to be_nil
            expect(poly_metadatum_existing.value).to eq(option_value)

            post :update, params: new_update_params # Update with new value
            study.reload

            # Updated
            poly_metadatum = study.poly_metadatum_by_key(option_key)
            expect(poly_metadatum).not_to be_nil
            expect(poly_metadatum.value).to eq(new_option_value) # New value
            expect(poly_metadatum.id).to eq(poly_metadatum_existing.id) # Same record
          end
        end

        context 'with empty value' do
          let(:new_option_value) { '' }

          it 'does not create poly_metadatum' do
            # Existing
            poly_metadatum_existing = study.poly_metadatum_by_key(option_key)
            expect(poly_metadatum_existing).not_to be_nil
            expect(poly_metadatum_existing.value).to eq(option_value)

            post :update, params: new_update_params # Update with new value
            study.reload

            # Updated
            poly_metadatum = study.poly_metadatum_by_key(option_key)
            expect(poly_metadatum).to be_nil # Deleted
          end
        end
      end
    end
  end

  describe '#grant_role' do
    let(:user) { create(:admin) }

    before do
      session[:user] = user.id
      post :grant_role, params: { role: { user: user.id, authorizable_type: 'manager' }, id: study.id }, xhr: true
    end

    it 'works', :aggregate_failures do # rubocop:todo RSpec/ExampleWording
      expect(subject).to respond_with :ok
      expect(subject).to set_flash.now.to('Role added')
    end
  end
end
