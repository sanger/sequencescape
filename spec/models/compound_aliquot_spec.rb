# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CompoundAliquot do
  describe 'validations' do
    let(:study) { create(:study) }
    let(:project) { create(:project) }
    let(:tag) { create(:tag) }
    let(:tag2) { create(:tag) }
    let(:request) { instance_double(Request, initial_study: nil, initial_project: nil, initial_project_id: nil) }

    describe '#tag_depth_is_unique' do
      context 'when all tag_depths are unique' do
        let(:aliquot1) { build(:tagged_aliquot, tag: tag, tag2: tag2, study: study, project: project, tag_depth: 1) }
        let(:aliquot2) { build(:tagged_aliquot, tag: tag, tag2: tag2, study: study, project: project, tag_depth: 2) }
        let(:compound_aliquot) { build(:compound_aliquot, request: request, source_aliquots: [aliquot1, aliquot2]) }

        it { expect(compound_aliquot).to be_valid }
      end

      context 'when tag_depths are duplicated' do
        let(:aliquot1) { build(:tagged_aliquot, tag: tag, tag2: tag2, study: study, project: project, tag_depth: 1) }
        let(:aliquot2) { build(:tagged_aliquot, tag: tag, tag2: tag2, study: study, project: project, tag_depth: 1) }
        let(:compound_aliquot) { build(:compound_aliquot, request: request, source_aliquots: [aliquot1, aliquot2]) }

        it { expect(compound_aliquot).not_to be_valid }

        it 'adds an error message' do
          compound_aliquot.valid?
          expect(compound_aliquot.errors[:base]).to include(
            include("Cannot create compound sample from following samples due to duplicate 'tag depth'")
          )
        end

        it 'includes sample names in error message' do
          compound_aliquot.valid?
          error_message = compound_aliquot.errors[:base].first
          expect(error_message).to include(aliquot1.sample.name, aliquot2.sample.name)
        end
      end

      context 'when multiple duplicates exist' do
        let(:aliquot1) { build(:tagged_aliquot, tag: tag, tag2: tag2, study: study, project: project, tag_depth: 1) }
        let(:aliquot2) { build(:tagged_aliquot, tag: tag, tag2: tag2, study: study, project: project, tag_depth: 1) }
        let(:aliquot3) { build(:tagged_aliquot, tag: tag, tag2: tag2, study: study, project: project, tag_depth: 2) }
        let(:aliquot4) { build(:tagged_aliquot, tag: tag, tag2: tag2, study: study, project: project, tag_depth: 2) }
        let(:compound_aliquot) do
          build(:compound_aliquot, request: request, source_aliquots: [aliquot1, aliquot2, aliquot3, aliquot4])
        end

        it { expect(compound_aliquot).not_to be_valid }
      end
    end

    describe '#source_aliquots_have_same_study' do
      let(:study1) { create(:study) }
      let(:study2) { create(:study) }
      let(:aliquot1) { build(:tagged_aliquot, tag: tag, tag2: tag2, study: study1, project: project) }
      let(:aliquot2) { build(:tagged_aliquot, tag: tag, tag2: tag2, study: study2, project: project) }

      context 'when all source aliquots have the same study' do
        let(:compound_aliquot) { build(:compound_aliquot, request: request, source_aliquots: [aliquot1]) }

        it { expect(compound_aliquot).to be_valid }
      end

      context 'when source aliquots have different studies' do
        let(:compound_aliquot) { build(:compound_aliquot, request: request, source_aliquots: [aliquot1, aliquot2]) }

        it { expect(compound_aliquot).not_to be_valid }

        it 'adds an error message' do
          compound_aliquot.valid?
          expect(compound_aliquot.errors[:base]).to include(
            include('Cannot create compound sample due to the component samples being under different studies')
          )
        end
      end

      context 'when request has an initial_study' do
        let(:initial_study) { create(:study) }
        let(:request_with_study) do
          instance_double(Request, initial_study: initial_study, initial_project: nil, initial_project_id: nil)
        end
        let(:aliquot1) { build(:tagged_aliquot, tag: tag, tag2: tag2, study: study1, project: project, tag_depth: 1) }
        let(:aliquot2) { build(:tagged_aliquot, tag: tag, tag2: tag2, study: study2, project: project, tag_depth: 2) }
        let(:compound_aliquot) do
          build(:compound_aliquot, request: request_with_study, source_aliquots: [aliquot1, aliquot2])
        end

        it 'allows different studies on aliquots' do
          expect(compound_aliquot).to be_valid
        end
      end
    end

    describe '#source_aliquots_have_same_project' do
      let(:project1) { create(:project) }
      let(:project2) { create(:project) }
      let(:aliquot1) { build(:tagged_aliquot, tag: tag, tag2: tag2, study: study, project: project1) }
      let(:aliquot2) { build(:tagged_aliquot, tag: tag, tag2: tag2, study: study, project: project2) }

      context 'when all source aliquots have the same project' do
        let(:compound_aliquot) { build(:compound_aliquot, request: request, source_aliquots: [aliquot1]) }

        it { expect(compound_aliquot).to be_valid }
      end

      context 'when source aliquots have different projects' do
        let(:compound_aliquot) { build(:compound_aliquot, request: request, source_aliquots: [aliquot1, aliquot2]) }

        it { expect(compound_aliquot).not_to be_valid }

        it 'adds an error message' do
          compound_aliquot.valid?
          expect(compound_aliquot.errors[:base]).to include(
            include('Cannot create compound sample due to the component samples being under different projects')
          )
        end
      end

      context 'when request has an initial_project' do
        let(:initial_project) { create(:project) }
        let(:request_with_project) do
          instance_double(Request, initial_study: nil, initial_project: initial_project,
                                   initial_project_id: initial_project.id)
        end
        let(:aliquot1) { build(:tagged_aliquot, tag: tag, tag2: tag2, study: study, project: project1, tag_depth: 1) }
        let(:aliquot2) { build(:tagged_aliquot, tag: tag, tag2: tag2, study: study, project: project2, tag_depth: 2) }
        let(:compound_aliquot) do
          build(:compound_aliquot, request: request_with_project, source_aliquots: [aliquot1, aliquot2])
        end

        it 'allows different projects on aliquots' do
          expect(compound_aliquot).to be_valid
        end
      end
    end
  end

  describe '#component_samples' do
    let(:study) { create(:study) }
    let(:project) { create(:project) }
    let(:tag) { create(:tag) }
    let(:tag2) { create(:tag) }
    let(:request) { instance_double(Request, initial_study: nil, initial_project: nil, initial_project_id: nil) }
    let(:sample1) { create(:sample) }
    let(:sample2) { create(:sample) }
    let(:sample3) { create(:sample) }
    let(:aliquot1) do
      build(:tagged_aliquot, sample: sample1, tag: tag, tag2: tag2, study: study, project: project, tag_depth: 1)
    end
    let(:aliquot2) do
      build(:tagged_aliquot, sample: sample2, tag: tag, tag2: tag2, study: study, project: project, tag_depth: 2)
    end
    let(:aliquot3) do
      build(:tagged_aliquot, sample: sample3, tag: tag, tag2: tag2, study: study, project: project, tag_depth: 3)
    end
    let(:compound_aliquot) do
      build(:compound_aliquot, request: request, source_aliquots: [aliquot1, aliquot2, aliquot3])
    end

    it 'returns samples from source aliquots' do
      expect(compound_aliquot.component_samples).to contain_exactly(sample1, sample2, sample3)
    end

    it 'caches the component samples' do
      expect(compound_aliquot.component_samples).to equal(compound_aliquot.component_samples)
    end

    it 'resets cache when source_aliquots are reassigned' do
      original_samples = compound_aliquot.component_samples
      compound_aliquot.source_aliquots = [aliquot1]
      expect(compound_aliquot.component_samples).not_to equal(original_samples)
    end

    it 'returns new component_samples after source_aliquots are reassigned' do
      compound_aliquot.source_aliquots = [aliquot1]
      expect(compound_aliquot.component_samples).to eq([sample1])
    end
  end

  describe '#default_compound_study' do
    let(:study1) { create(:study) }
    let(:study2) { create(:study) }
    let(:project) { create(:project) }
    let(:tag) { create(:tag) }
    let(:tag2) { create(:tag) }

    context 'when request has an initial_study' do
      let(:initial_study) { create(:study) }
      let(:request) do
        instance_double(Request, initial_study: initial_study, initial_project: nil, initial_project_id: nil)
      end
      let(:aliquot) { build(:tagged_aliquot, tag: tag, tag2: tag2, study: study1, project: project) }
      let(:compound_aliquot) { build(:compound_aliquot, request: request, source_aliquots: [aliquot]) }

      it 'returns the request initial_study' do
        expect(compound_aliquot.default_compound_study).to eq(initial_study)
      end
    end

    context 'when request has no initial_study' do
      let(:request) { instance_double(Request, initial_study: nil, initial_project: nil, initial_project_id: nil) }
      let(:aliquot) { build(:tagged_aliquot, tag: tag, tag2: tag2, study: study1, project: project) }
      let(:compound_aliquot) { build(:compound_aliquot, request: request, source_aliquots: [aliquot]) }

      it 'returns the study from the first source aliquot' do
        expect(compound_aliquot.default_compound_study).to eq(study1)
      end
    end
  end

  describe '#default_compound_project_id' do
    let(:study) { create(:study) }
    let(:project1) { create(:project) }
    let(:project2) { create(:project) }
    let(:tag) { create(:tag) }
    let(:tag2) { create(:tag) }

    context 'when request has an initial_project_id' do
      let(:initial_project_id) { project1.id }
      let(:request) do
        instance_double(Request, initial_study: nil, initial_project: project1, initial_project_id: initial_project_id)
      end
      let(:aliquot) { build(:tagged_aliquot, tag: tag, tag2: tag2, study: study, project: project2) }
      let(:compound_aliquot) { build(:compound_aliquot, request: request, source_aliquots: [aliquot]) }

      it 'returns the request initial_project_id' do
        expect(compound_aliquot.default_compound_project_id).to eq(initial_project_id)
      end
    end

    context 'when request has no initial_project_id' do
      let(:request) { instance_double(Request, initial_study: nil, initial_project: nil, initial_project_id: nil) }
      let(:aliquot) { build(:tagged_aliquot, tag: tag, tag2: tag2, study: study, project: project1) }
      let(:compound_aliquot) { build(:compound_aliquot, request: request, source_aliquots: [aliquot]) }

      it 'returns the project_id from the first source aliquot' do
        expect(compound_aliquot.default_compound_project_id).to eq(project1.id)
      end
    end
  end

  describe '#default_library_type' do
    let(:study) { create(:study) }
    let(:project) { create(:project) }
    let(:tag) { create(:tag) }
    let(:tag2) { create(:tag) }
    let(:request) { instance_double(Request, initial_study: nil, initial_project: nil, initial_project_id: nil) }

    context 'when all source aliquots have the same library_type' do
      let(:aliquot1) do
        build(:tagged_aliquot, tag: tag, tag2: tag2, study: study, project: project, library_type: 'Standard')
      end
      let(:aliquot2) do
        build(:tagged_aliquot, tag: tag, tag2: tag2, study: study, project: project, library_type: 'Standard')
      end
      let(:compound_aliquot) { build(:compound_aliquot, request: request, source_aliquots: [aliquot1, aliquot2]) }

      it 'returns the library_type' do
        expect(compound_aliquot.default_library_type).to eq('Standard')
      end
    end

    context 'when source aliquots have different library_types' do
      let(:aliquot1) do
        build(:tagged_aliquot, tag: tag, tag2: tag2, study: study, project: project, library_type: 'Standard')
      end
      let(:aliquot2) do
        build(:tagged_aliquot, tag: tag, tag2: tag2, study: study, project: project, library_type: 'Custom')
      end
      let(:compound_aliquot) { build(:compound_aliquot, request: request, source_aliquots: [aliquot1, aliquot2]) }

      it 'returns nil' do
        expect(compound_aliquot.default_library_type).to be_nil
      end
    end

    context 'when library_type is nil' do
      let(:aliquot) { build(:tagged_aliquot, tag: tag, tag2: tag2, study: study, project: project, library_type: nil) }
      let(:compound_aliquot) { build(:compound_aliquot, request: request, source_aliquots: [aliquot]) }

      it 'returns nil' do
        expect(compound_aliquot.default_library_type).to be_nil
      end
    end
  end

  describe '#default_library_id' do
    let(:study) { create(:study) }
    let(:project) { create(:project) }
    let(:tag) { create(:tag) }
    let(:tag2) { create(:tag) }
    let(:request) { instance_double(Request, initial_study: nil, initial_project: nil, initial_project_id: nil) }
    let(:library1) { create(:library_tube) }
    let(:library2) { create(:library_tube) }

    context 'when all source aliquots have the same library_id' do
      let(:aliquot1) { build(:tagged_aliquot, tag: tag, tag2: tag2, study: study, project: project, library: library1) }
      let(:aliquot2) { build(:tagged_aliquot, tag: tag, tag2: tag2, study: study, project: project, library: library1) }
      let(:compound_aliquot) { build(:compound_aliquot, request: request, source_aliquots: [aliquot1, aliquot2]) }

      it 'returns the library_id' do
        expect(compound_aliquot.default_library_id).to eq(library1.receptacle.id)
      end
    end

    context 'when source aliquots have different library_ids' do
      let(:aliquot1) { build(:tagged_aliquot, tag: tag, tag2: tag2, study: study, project: project, library: library1) }
      let(:aliquot2) { build(:tagged_aliquot, tag: tag, tag2: tag2, study: study, project: project, library: library2) }
      let(:compound_aliquot) { build(:compound_aliquot, request: request, source_aliquots: [aliquot1, aliquot2]) }

      it 'returns nil' do
        expect(compound_aliquot.default_library_id).to be_nil
      end
    end
  end

  describe '#tag_id' do
    let(:study) { create(:study) }
    let(:project) { create(:project) }
    let(:tag) { create(:tag) }
    let(:tag2) { create(:tag) }
    let(:request) { instance_double(Request, initial_study: nil, initial_project: nil, initial_project_id: nil) }
    let(:aliquot1) { build(:tagged_aliquot, tag:, tag2:, study:, project:) }
    let(:aliquot2) { build(:tagged_aliquot, tag:, tag2:, study:, project:) }
    let(:compound_aliquot) { build(:compound_aliquot, request: request, source_aliquots: [aliquot1, aliquot2]) }

    it 'returns the tag_id from the first source aliquot' do
      expect(compound_aliquot.tag_id).to eq(tag.id)
    end
  end

  describe '#tag2_id' do
    let(:study) { create(:study) }
    let(:project) { create(:project) }
    let(:tag) { create(:tag) }
    let(:tag2) { create(:tag) }
    let(:request) { instance_double(Request, initial_study: nil, initial_project: nil, initial_project_id: nil) }
    let(:aliquot1) { build(:tagged_aliquot, tag:, tag2:, study:, project:) }
    let(:aliquot2) { build(:tagged_aliquot, tag:, tag2:, study:, project:) }
    let(:compound_aliquot) { build(:compound_aliquot, request: request, source_aliquots: [aliquot1, aliquot2]) }

    it 'returns the tag2_id from the first source aliquot' do
      expect(compound_aliquot.tag2_id).to eq(tag2.id)
    end
  end

  describe '#aliquot_attributes' do
    let(:study) { create(:study) }
    let(:project) { create(:project) }
    let(:tag) { create(:tag) }
    let(:tag2) { create(:tag) }
    let(:request) { instance_double(Request, initial_study: nil, initial_project: nil, initial_project_id: nil) }
    let(:aliquot1) do
      create(:tagged_aliquot, tag: tag, tag2: tag2, study: study, project: project, library_type: 'Standard',
                             tag_depth: 1)
    end
    let(:aliquot2) do
      create(:tagged_aliquot, tag: tag, tag2: tag2, study: study, project: project, library_type: 'Standard',
                             tag_depth: 2)
    end
    let(:compound_aliquot) { build(:compound_aliquot, request: request, source_aliquots: [aliquot1, aliquot2]) }

    # rubocop:disable RSpec/ExampleLength
    it 'returns a hash with expected keys' do
      attrs = compound_aliquot.aliquot_attributes
      expect(attrs).to include(
        :tag_id,
        :tag2_id,
        :library_type,
        :study_id,
        :project_id,
        :library_id,
        :sample
      )
    end
    # rubocop:enable RSpec/ExampleLength

    it 'includes tag_id from source aliquots' do
      expect(compound_aliquot.aliquot_attributes[:tag_id]).to eq(tag.id)
    end

    it 'includes tag2_id from source aliquots' do
      expect(compound_aliquot.aliquot_attributes[:tag2_id]).to eq(tag2.id)
    end

    it 'includes default_library_type' do
      expect(compound_aliquot.aliquot_attributes[:library_type]).to eq('Standard')
    end

    it 'includes default_compound_study id' do
      expect(compound_aliquot.aliquot_attributes[:study_id]).to eq(study.id)
    end

    it 'includes default_compound_project_id' do
      expect(compound_aliquot.aliquot_attributes[:project_id]).to eq(project.id)
    end
  end
end
