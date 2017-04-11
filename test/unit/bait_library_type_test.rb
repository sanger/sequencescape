# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2012,2015,2016 Genome Research Ltd.

require 'test_helper'

class BaitLibraryTypeTest < ActiveSupport::TestCase
  context 'When a bait library exists' do
    setup do
      @bait_library = create :bait_library
    end

    should 'Bait Library Types exist' do
      assert BaitLibraryType.count > 0
    end

    should 'bait libraries have library types' do
      assert @bait_library.bait_library_type
    end
  end

  context 'A request with a bait library' do
    setup do
      @sample = create :sample

      @pulldown_request_type = create :request_type, name: 'Bait Pulldown', target_asset_type: nil
      @sequencing_request_type = create :request_type, name: 'Single ended sequencing2'
      @submission = FactoryHelp::submission(request_types: [@pulldown_request_type, @sequencing_request_type].map(&:id), asset_group_name: 'to avoid asset errors')
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

    should 'have a bait library type' do
      assert BaitLibrary.find(@request1.request_metadata.bait_library_id).bait_library_type
    end
  end
end
