require 'rails_helper'

RSpec.describe Submission, type: :model do
  def orders_compatible?(a, b, key = nil)
    submission = Submission.new(user: create(:user), orders: [a, b])
    submission.save!
    true
  rescue ActiveRecord::RecordInvalid
    if key
      !submission.errors[key]
    else
      false
    end
  end

  context '#priority' do
    setup do
      @submission = Submission.new(user: create(:user))
    end

    it 'be 0 by default' do
      assert_equal 0, @submission.priority
    end

    it 'be changable' do
      @submission.priority = 3
      assert @submission.valid?
      assert_equal 3, @submission.priority
    end

    it 'have a maximum of 3' do
      @submission.priority = 4
      assert_equal false, @submission.valid?
    end
  end

  context '#orders compatible' do
    setup do
      @study1 = create :study
      @study2 = create :study

      @project =  create :project
      @project2 = create :project

      @asset1 = create :empty_sample_tube
      @asset1.aliquots.create!(sample: create(:sample, studies: [@study1]))
      @asset2 = create :empty_sample_tube
      @asset2.aliquots.create!(sample: create(:sample, studies: [@study2]))

      @reference_genome1 = create :reference_genome, name: 'genome 1'
      @reference_genome2 = create :reference_genome, name: 'genome 2'

      @order1 = create :order, study: @study1, assets: [@asset1], project: @project
      @order2 = create :order, study: @study2, assets: [@asset2], project: @project
    end

    context 'with compatible requests' do
      setup do
        @order2.request_types = @order1.request_types
      end

      context 'and study with same reference genome' do
        setup do
          @study1.reference_genome = @reference_genome1
          @study2.reference_genome = @reference_genome1
        end

        it 'be compatible' do
          assert orders_compatible?(@order1, @order2)
        end
      end
      context 'and study with different contaminated human DNA policy' do
        setup do
          @study1.study_metadata.contaminated_human_dna = true
          @study2.study_metadata.contaminated_human_dna = false
        end

        it 'be incompatible' do
          assert_equal false, orders_compatible?(@order1, @order2)
        end
      end

      context 'and incompatible request options' do
        setup do
          @order1.request_options = { option: 'value' }
        end

        it 'be incompatible' do
          assert_equal false, orders_compatible?(@order1, @order2, :request_options)
        end
      end

      context 'and different projects' do
        setup do
          @order2.project = @project2
        end

        it 'be incompatible' do
          assert_equal false, orders_compatible?(@order1, @order2)
        end
      end
    end
  end

  it 'knows all samples that can not be included in submission' do
    sample_manifest = create :tube_sample_manifest_with_samples
    sample_manifest.samples.first.sample_metadata.update_attributes(supplier_name: 'new_name')
    samples = sample_manifest.samples[1..-1]
    order1 = create :order, assets: sample_manifest.labware

    asset = create :empty_sample_tube
    no_manifest_sample = create :sample, assets: [asset]
    order2 = create :order, assets: no_manifest_sample.assets

    submission = Submission.new(user: create(:user), orders: [order1, order2])

    expect(submission.not_ready_samples).to eq samples
  end
end
