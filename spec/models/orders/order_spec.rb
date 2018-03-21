# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Order, type: :model do
  attr_reader :study, :asset, :project

  before(:each) do
    @study = create :study, state: 'pending'
    @project = create :project
    @asset = create :empty_sample_tube
  end

  context 'An order' do
    setup do
      @shared_template = 'shared_template'
      @asset_a = create :sample_tube
      @order   = create :order, assets: [@asset_a], template_name: @shared_template
    end

    it 'not detect duplicates when there are none' do
      refute @order.duplicates_within(1.month)
    end

    context 'with the same asset in a different order' do
      setup do
        @other_template = 'other_template'
        @secondary_order = create :order, assets: [@asset_a], template_name: @other_template
      end
      it 'not detect duplicates' do
        refute @order.duplicates_within(1.month)
      end
    end

    context 'with the same sample in a similar order' do
      setup do
        @asset_b = create :sample_tube, sample: @asset_a.samples.first
        @secondary_submission = create :submission
        @secondary_order = create :order, assets: [@asset_b], template_name: @shared_template, submission: @secondary_submission
      end
      it 'detect duplicates' do
        assert @order.duplicates_within(1.month)
      end
      it 'yield the samples, order and submission to a block' do
        yielded = false
        @order.duplicates_within(1.month) do |samples, orders, submissions|
          yielded = true
          assert_equal [@asset_a.samples.first], samples
          assert_equal [@secondary_order], orders
          assert_equal [@secondary_submission], submissions
        end
        assert yielded, 'duplicates_within failed to yield'
      end
    end

    context 'with no sequencing requests' do
      it 'not be a sequencing order' do
        refute @order.is_a_sequencing_order?
      end
    end

    %w[SequencingRequest PacBioSequencingRequest].each do |request_class|
      context "with #{request_class}" do
        setup do
          @sequencing_request_type = create :request_type, request_class_name: request_class
          @order.request_types << @sequencing_request_type.id
        end
        it 'be a sequencing order' do
          assert @order.is_a_sequencing_order?
        end
      end
    end
  end

  it 'order should not be valid if study is not active' do
    order = build :order, study: study, assets: [asset], project: project
    refute order.valid?
  end

  it 'order should be valid if study is active on create' do
    study.activate!
    order = create :order, study: study, assets: [asset], project: project
    assert order.valid?
    study.deactivate!
    new_asset = create :empty_sample_tube
    order.assets << new_asset
    assert order.valid?
  end

  it 'should know if it has samples that can not be included in submission' do
    sample_manifest = create :tube_sample_manifest_with_samples
    order = create :order, assets: sample_manifest.labware
    expect(order.not_ready_samples.count).to eq 5
    sample = sample_manifest.samples.first
    sample.sample_metadata.update_attributes(supplier_name: 'new_name')
    expect(order.reload.not_ready_samples.count).to eq 4

    no_manifest_sample = create :sample, assets: [asset]
    order = create :order, assets: no_manifest_sample.assets
    expect(order.all_samples).to_not be_empty
    expect(order.not_ready_samples).to be_empty
  end
end
