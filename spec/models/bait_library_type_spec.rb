
require 'rails_helper'

describe BaitLibraryType do
  context 'When a bait library exists' do
    let(:bait_library) { create :bait_library }

    it 'Bait Library Types exist' do
      expect(BaitLibraryType.count > 0).to be true
    end

    it 'bait libraries have library types' do
      expect(bait_library.bait_library_type).to be_truthy
    end

    it 'has a short_name' do
      standard_bait_library_type = BaitLibraryType.new(name: 'Standard - test')
      expect(standard_bait_library_type.short_name).to eq 'standard'
      custom_bait_library_type = BaitLibraryType.new(name: 'Custom')
      expect(custom_bait_library_type.short_name).to eq 'custom'
    end
  end

  context 'A request with a bait library' do
    before do
      @sample = create :sample

      @pulldown_request_type = create :request_type, name: 'Bait Pulldown', target_asset_type: nil
      @sequencing_request_type = create :request_type, name: 'Single ended sequencing2'
      @submission = FactoryHelp.submission(request_types: [@pulldown_request_type, @sequencing_request_type].map(&:id), asset_group_name: 'to avoid asset errors')
      @item = create :item, submission: @submission

      @genotype_pipeline = create :pipeline, name: 'Cluster formation SE2', request_types: [@sequencing_request_type]
      @pulldown_pipeline = create :pipeline, name: 'Bait Pulldown', request_types: [@pulldown_request_type], next_pipeline_id: @genotype_pipeline.id, asset_type: 'LibraryTube'

      @request1 = create(
        :request_without_assets,
        item: @item,
        asset: create(:empty_sample_tube).tap { |sample_tube| sample_tube.aliquots.create!(sample: @sample) },
        target_asset: nil,
        submission: @submission,
        request_type: @pulldown_request_type,
        pipeline: @pulldown_pipeline
      )

      # @request1.request_metadata.bait_library = create(:bait_library)
    end

    it 'have a bait library type' do
      expect(BaitLibrary.find(@request1.request_metadata.bait_library_id).bait_library_type).to be_truthy
    end
  end
end
