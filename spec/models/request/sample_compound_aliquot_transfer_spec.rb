# frozen_string_literal: true

require 'rails_helper'

# Test for module to provide support to create a compound sample during the
# sequencing request start from all the samples at source of the request
RSpec.describe 'Request::SampleCompoundAliquotTransfer' do
  let(:samples) { create_list :sample, 3 }
  let(:study1) { create :study }
  let(:study2) { create :study }
  let(:project1) { create :project }
  let(:project2) { create :project }
  let(:destination) { create :receptacle }
  let(:source) { create :receptacle, aliquots: [aliquot1, aliquot2] }
  let(:library_tube) { create :library_tube, receptacles: [source] }
  let(:sequencing_request) do
    create(:sequencing_request, asset: source, target_asset: destination, initial_study_id: study1.id)
  end
  let(:tags) { create_list :tag, 3 }

  describe '#compound_samples_needed?' do
    context 'when number of aliquots is 1' do
      let(:aliquot1) { create :aliquot, sample: samples[0], tag_id: 1, tag_depth: 1, project: project1 }
      let(:source) { create :receptacle, aliquots: [aliquot1] }

      it 'returns false' do
        expect(sequencing_request).not_to be_compound_samples_needed
      end
    end

    context 'when there is no tag clash, using tags 1 and 2' do
      let(:aliquot1) { create :aliquot, sample: samples[0], tag_id: tags[0].id, tag2_id: tags[1].id, project: project1 }
      let(:aliquot2) { create :aliquot, sample: samples[1], tag_id: tags[0].id, tag2_id: tags[2].id, project: project1 }

      it 'returns false' do
        expect(sequencing_request).not_to be_compound_samples_needed
      end
    end

    context 'when there is a tag clash, using tags 1 and 2' do
      let(:aliquot1) do
        create :aliquot, sample: samples[0], tag_id: tags[0].id, tag2_id: tags[1].id, tag_depth: 1, project: project1
      end
      let(:aliquot2) do
        create :aliquot, sample: samples[1], tag_id: tags[0].id, tag2_id: tags[1].id, tag_depth: 2, project: project1
      end

      it 'returns true' do
        expect(sequencing_request).to be_compound_samples_needed
      end
    end
  end

  describe '#transfer_aliquots_into_compound_sample_aliquots' do
    let(:aliquot1) do
      create :aliquot,
             sample: samples[0],
             tag_id: tags[0].id,
             tag2_id: tags[1].id,
             tag_depth: 1,
             study: study1,
             project: project1,
             library_type: 'Standard',
             library_id: 54
    end
    let(:aliquot2) do
      create :aliquot,
             sample: samples[1],
             tag_id: tags[0].id,
             tag2_id: tags[1].id,
             tag_depth: 2,
             study: study1,
             project: project1,
             library_type: 'Standard',
             library_id: 54
    end

    context 'when no compound sample exists with the component samples' do
      it 'creates a compound sample and transfers an aliquot to it' do
        expect(sequencing_request.target_asset.aliquots.count).to eq(0)

        expect { sequencing_request.transfer_aliquots_into_compound_sample_aliquots }.to change(Sample, :count).by(1)

        expect(sequencing_request.target_asset.aliquots.count).to eq(1)
        expect(sequencing_request.target_asset.aliquots.first.library_type).to eq('Standard')
        expect(sequencing_request.target_asset.aliquots.first.study).to eq(study1)
        expect(sequencing_request.target_asset.aliquots.first.project).to eq(project1)
        expect(sequencing_request.target_asset.aliquots.first.library_id).to eq(54)
        expect(sequencing_request.target_asset.samples.first.component_samples.count).to eq 2
        expect(sequencing_request.target_asset.samples.first.component_samples[0]).to eq samples[0]
        expect(sequencing_request.target_asset.samples.first.component_samples[1]).to eq samples[1]
      end
    end

    context 'when a compound sample exists with different component samples' do
      let(:compound_sample) { create(:sample, name: 'compound_sample_1') }

      before do
        compound_sample.update(component_samples: [samples[0], samples[2]])
        samples[0].reload
        samples[2].reload
      end

      it 'creates a compound sample and transfers an aliquot to it' do
        expect(sequencing_request.target_asset.aliquots.count).to eq(0)

        expect { sequencing_request.transfer_aliquots_into_compound_sample_aliquots }.to change(Sample, :count).by(1)

        expect(sequencing_request.target_asset.aliquots.count).to eq(1)
        expect(sequencing_request.target_asset.aliquots.first.library_type).to eq('Standard')
        expect(sequencing_request.target_asset.aliquots.first.study).to eq(study1)
        expect(sequencing_request.target_asset.aliquots.first.project).to eq(project1)
        expect(sequencing_request.target_asset.aliquots.first.library_id).to eq(54)
        expect(sequencing_request.target_asset.samples.first.component_samples.count).to eq 2
        expect(sequencing_request.target_asset.samples.first.component_samples[0]).to eq samples[0]
        expect(sequencing_request.target_asset.samples.first.component_samples[1]).to eq samples[1]
      end
    end

    context 'when a compound sample exists with the component samples' do
      let(:compound_sample) { create(:sample, name: 'compound_sample_1') }

      before do
        compound_sample.update(component_samples: [samples[0], samples[1]])
        samples[0].reload
        samples[1].reload
      end

      it 'gets the existing compound sample and transfers an aliquot to it' do
        expect(sequencing_request.target_asset.aliquots.count).to eq(0)

        expect { sequencing_request.transfer_aliquots_into_compound_sample_aliquots }.to change(Sample, :count).by(0)

        expect(sequencing_request.target_asset.aliquots.count).to eq(1)
        expect(sequencing_request.target_asset.samples.first).to eq(compound_sample)
        expect(sequencing_request.target_asset.aliquots.first.sample).to eq(compound_sample)
        expect(sequencing_request.target_asset.samples.first.component_samples).to eq([samples[0], samples[1]])
        expect(sequencing_request.target_asset.aliquots.first.library_type).to eq('Standard')
        expect(sequencing_request.target_asset.aliquots.first.study).to eq(study1)
        expect(sequencing_request.target_asset.aliquots.first.project).to eq(project1)
        expect(sequencing_request.target_asset.aliquots.first.library_id).to eq(54)
      end
    end

    context 'when multiple compound samples exists with the component samples' do
      let(:compound_sample1) { create(:sample) }
      let(:compound_sample2) { create(:sample) }

      before do
        compound_sample1.update(component_samples: [samples[0], samples[1]])
        compound_sample2.update(component_samples: [samples[0], samples[1]])
        samples[0].reload
        samples[1].reload
      end

      it 'gets the latest compound sample and transfers an aliquot to it' do
        expect(sequencing_request.target_asset.aliquots.count).to eq(0)

        expect { sequencing_request.transfer_aliquots_into_compound_sample_aliquots }.to change(Sample, :count).by(0)

        expect(sequencing_request.target_asset.aliquots.count).to eq(1)
        expect(sequencing_request.target_asset.samples.first).to eq(compound_sample2)
        expect(sequencing_request.target_asset.aliquots.first.sample).to eq(compound_sample2)
        expect(sequencing_request.target_asset.samples.first.component_samples).to eq([samples[0], samples[1]])
        expect(sequencing_request.target_asset.aliquots.first.library_type).to eq('Standard')
        expect(sequencing_request.target_asset.aliquots.first.study).to eq(study1)
        expect(sequencing_request.target_asset.aliquots.first.project).to eq(project1)
        expect(sequencing_request.target_asset.aliquots.first.library_id).to eq(54)
      end
    end

    # How the library_id should be set if the source aliquots have different library_ids is not defined
    # Therefore, set it to nil for now, until we have a real requirement
    context 'with conflicting library_ids and library_types' do
      before { aliquot1.update!(library_id: 82, library_type: 'Not Standard') }

      it 'creates a compound sample with a blank library id and library type' do
        sequencing_request.transfer_aliquots_into_compound_sample_aliquots
        expect(sequencing_request.target_asset.aliquots.count).to eq(1)
        expect(sequencing_request.target_asset.aliquots.first.library_id).to be_nil
        expect(sequencing_request.target_asset.aliquots.first.library_type).to be_nil
      end
    end

    context 'with a different study and project specified on the sequencing request to on the source aliquots' do
      before { sequencing_request.update!(initial_study_id: study2.id, initial_project_id: project2.id) }

      it 'uses the study and project from the request' do
        sequencing_request.transfer_aliquots_into_compound_sample_aliquots
        expect(sequencing_request.target_asset.aliquots.first.study).to eq(study2)
        expect(sequencing_request.target_asset.aliquots.first.project).to eq(project2)
      end
    end

    context 'with no study or project specified on the sequencing request' do
      before { sequencing_request.update!(initial_study_id: nil, initial_project_id: nil) }

      it 'uses the study and project from the source aliquots' do
        sequencing_request.transfer_aliquots_into_compound_sample_aliquots
        expect(sequencing_request.target_asset.aliquots.first.study).to eq(study1)
        expect(sequencing_request.target_asset.aliquots.first.project).to eq(project1)
      end

      # If the component samples are under different studies, this is a potential data governance issue
      # since the study controls data access. Error in this case.
      context 'with conflicting study_ids' do
        before { aliquot1.update!(study: study2) }

        it 'throws an exception' do
          expect { sequencing_request.transfer_aliquots_into_compound_sample_aliquots }.to raise_error(
            Request::SampleCompoundAliquotTransfer::Error,
            /#{CompoundAliquot::MULTIPLE_STUDIES_ERROR_MSG}/o
          )
        end
      end

      # If the component samples are under different projects, this could cause billing issues.
      # Error in this case.
      context 'with conflicting project_ids' do
        before { aliquot1.update!(project: project2) }

        it 'throws an exception' do
          expect { sequencing_request.transfer_aliquots_into_compound_sample_aliquots }.to raise_error(
            Request::SampleCompoundAliquotTransfer::Error,
            /#{CompoundAliquot::MULTIPLE_PROJECTS_ERROR_MSG}/o
          )
        end
      end
    end

    context 'when there are two compound samples' do
      let(:samples_extra) { create_list :sample, 2 }
      let(:aliquot3) do
        create :aliquot,
               sample: samples_extra[0],
               tag_id: tags_extra[0].id,
               tag2_id: tags_extra[1].id,
               tag_depth: 1,
               study: study2,
               project: project2,
               library_type: 'Standard',
               library_id: 55
      end
      let(:aliquot4) do
        create :aliquot,
               sample: samples_extra[1],
               tag_id: tags_extra[0].id,
               tag2_id: tags_extra[1].id,
               tag_depth: 2,
               study: study2,
               project: project2,
               library_type: 'Standard',
               library_id: 55
      end
      let(:tags_extra) { create_list :tag, 2 }
      let(:source) { create :receptacle, aliquots: [aliquot1, aliquot2, aliquot3, aliquot4] }

      before { sequencing_request.update!(initial_study_id: nil) }

      it 'creates 2 compound samples and transfers an aliquot of each' do
        expect(sequencing_request.target_asset.aliquots.count).to eq(0)
        sequencing_request.transfer_aliquots_into_compound_sample_aliquots
        expect(sequencing_request.target_asset.aliquots.count).to eq(2)
        expect(sequencing_request.target_asset.aliquots[0].library_type).to eq('Standard')
        expect(sequencing_request.target_asset.aliquots[1].library_type).to eq('Standard')
        expect(sequencing_request.target_asset.aliquots[0].study).to eq(study1)
        expect(sequencing_request.target_asset.aliquots[1].study).to eq(study2)
        expect(sequencing_request.target_asset.aliquots[0].project).to eq(project1)
        expect(sequencing_request.target_asset.aliquots[1].project).to eq(project2)
        expect(sequencing_request.target_asset.aliquots[0].library_id).to eq(54)
        expect(sequencing_request.target_asset.aliquots[1].library_id).to eq(55)
        expect(sequencing_request.target_asset.samples[0].component_samples.count).to eq 2
        expect(sequencing_request.target_asset.samples[0].component_samples[0]).to eq samples[0]
        expect(sequencing_request.target_asset.samples[0].component_samples[1]).to eq samples[1]
        expect(sequencing_request.target_asset.samples[1].component_samples.count).to eq 2
        expect(sequencing_request.target_asset.samples[1].component_samples[0]).to eq samples_extra[0]
        expect(sequencing_request.target_asset.samples[1].component_samples[1]).to eq samples_extra[1]
      end
    end
  end
end
