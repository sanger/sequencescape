# frozen_string_literal: true

require 'rails_helper'
require_relative 'shared_order_specs'

RSpec.describe Order, type: :model do
  let(:study) { create :study, state: study_state }
  let(:study_state) { 'pending' }
  let(:project) { create :project }
  let(:asset) { create :empty_sample_tube }

  describe '#autodetect_studies_projects' do
    # When automating submission creation, it is really useful if we can
    # auto-detect studies and projects based on their aliquots. However we
    # don't want to trigger this behaviour accidentally if someone forgets to
    # specify a study.

    subject do
      build :order, assets: assets, autodetect_studies_projects: autodetect_studies_projects, study: nil, project: nil
    end

    let(:assets) { [tube] }
    let(:tube) { create :sample_tube, aliquots: aliquots }
    let(:study_state) { 'active' }

    context 'with autodetect_studies_projects set to true' do
      let(:autodetect_studies_projects) { true }

      it_behaves_like 'an automated order'

      context 'with a cross study/project tube' do
        let(:aliquots) { create_list :tagged_aliquot, 2 }

        # We may wish to relax this in future. I'm keeping the restriction in
        # place for the time being solely because we don't need the
        # functionality, and I don't want to introduce unnecessary behaviour
        # changes
        it { is_expected.not_to be_valid }
      end
    end

    context 'with autodetect_studies_projects set to false' do
      let(:autodetect_studies_projects) { false }
      let(:aliquots) { create_list :tagged_aliquot, 2, study: study, project: project }

      it { is_expected.not_to be_valid }
    end
  end

  context 'An order' do
    let(:shared_template) { 'shared_template' }
    let(:asset_a) { create :sample_tube }
    let(:order) { create :order, assets: [asset_a], template_name: shared_template }

    it 'not detect duplicates when there are none' do
      expect(order.duplicates_within(1.month)).not_to be_truthy
    end

    context 'with the same asset in a different order' do
      before { create :order, assets: [asset_a], template_name: 'other_template' }

      it 'not detect duplicates' do
        expect(order.duplicates_within(1.month)).not_to be_truthy
      end
    end

    context 'with the same sample in a similar order' do
      before do
        @asset_b = create :sample_tube, sample: asset_a.samples.first
        @secondary_submission = create :submission
        @secondary_order =
          create :order, assets: [@asset_b], template_name: shared_template, submission: @secondary_submission
      end

      it 'detect duplicates' do
        assert order.duplicates_within(1.month)
      end

      it 'yield the samples, order and submission to a block' do
        yielded = false
        order.duplicates_within(1.month) do |samples, orders, submissions|
          yielded = true
          assert_equal [asset_a.samples.first], samples
          assert_equal [@secondary_order], orders
          assert_equal [@secondary_submission], submissions
        end
        assert yielded, 'duplicates_within failed to yield'
      end
    end

    context 'with no sequencing requests' do
      it 'not be a sequencing order' do
        expect(order.sequencing_order?).to be false
      end
    end

    %w[SequencingRequest].each do |request_class|
      context "with #{request_class}" do
        before do
          @sequencing_request_type = create :request_type, request_class_name: request_class
          order.request_types << @sequencing_request_type.id
        end

        it 'be a sequencing order' do
          expect(order.sequencing_order?).to be true
        end
      end
    end
  end

  it 'order should not be valid if study is not active' do
    order = build :order, study: study, assets: [asset.receptacle], project: project
    expect(order).not_to be_valid
  end

  it 'order should be valid if study is active on create' do
    study.activate!
    order = create :order, study: study, assets: [asset.receptacle], project: project
    assert order.valid?
    study.deactivate!
    new_asset = create :empty_sample_tube
    order.assets << new_asset
    assert order.valid?
  end

  it 'knows if it has samples that can not be included in submission' do
    sample_manifest = create :tube_sample_manifest_with_samples
    order = create :order, assets: sample_manifest.labware
    expect(order.not_ready_samples.count).to eq 5
    sample = sample_manifest.samples.first
    sample.sample_metadata.update(supplier_name: 'new_name')
    expect(order.reload.not_ready_samples.count).to eq 4

    sample_tube_without_manifest = create_list :sample_tube, 1
    order = create :order, assets: sample_tube_without_manifest
    expect(order.all_samples).not_to be_empty
    expect(order.not_ready_samples).to be_empty
  end
end
