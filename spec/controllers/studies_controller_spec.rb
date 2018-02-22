# frozen_string_literal: true

require 'rails_helper'

RSpec.describe StudiesController do
  it_behaves_like 'it requires login'

  let(:user) { create(:owner) }
  let(:program) { create(:program) }
  let(:study) { create :study }

  setup do
    session[:user] = user.id
  end

  describe '#new' do
    setup { get :new }
    it { is_expected.to respond_with :success }
    it { is_expected.to render_template :new }
  end

  describe '#create' do
    setup do
      @study_count = Study.count
      post :create, params: params
    end

    context 'with valid options' do
      let(:params) do
        { 'study' => {
          'name' => 'hello',
          'reference_genome_id' => ReferenceGenome.find_by(name: '').id,
          'study_metadata_attributes' => {
            'faculty_sponsor_id' => FacultySponsor.create!(name: 'Me'),
            'study_description' => 'some new study',
            'program_id' => program.id,
            'contains_human_dna' => 'No',
            'contaminated_human_dna' => 'No',
            'commercially_available' => 'No',
            'data_release_study_type_id' => DataReleaseStudyType.find_by(name: 'genomic sequencing'),
            'data_release_strategy' => 'open',
            'study_type_id' => StudyType.find_by(name: 'Not specified').id
          }
        } }
      end
      it { is_expected.to set_flash.to('Your study has been created') }
      it { is_expected.to redirect_to('study path') { study_path(Study.last) } }
      it 'changes Study.count by 1' do
        assert_equal 1, Study.count - @study_count
      end
    end

    context 'with invalid options' do
      setup do
        @initial_study_count = Study.count
        post :create, params: { 'study' => { 'name' => 'hello 2' } }
      end

      let(:params) do
        {
          'study' => { 'name' => 'hello 2' }
        }
      end

      it { is_expected.to render_template :new }

      it 'not change Study.count' do
        assert_equal @initial_study_count, Study.count
      end

      it { is_expected.to set_flash.now.to('Problems creating your new study') }
    end
  end

  describe '#grant_role' do
    let(:user) { create :admin }

    before do
      session[:user] = user.id
      post :grant_role, params: { role: { user: user.id, authorizable_type: 'manager' }, id: study.id }, xhr: true
    end

    it { is_expected.to respond_with :ok }
    it { is_expected.to set_flash.now.to('Role added') }
  end
end
