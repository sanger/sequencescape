# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2011,2012,2015 Genome Research Ltd.

require 'test_helper'

class MultiplexedLibraryCreationPipelineTest < ActiveSupport::TestCase
  def setup
    @pipeline = Pipeline.find_by(name: 'Illumina-B MX Library Preparation') or raise StandardError, 'Cannot find the Illumina-B MX Library Preparation pipeline'
    @user     = create(:user)
  end

  context 'batch interaction' do
    setup do
      @batch = create(:batch, pipeline: @pipeline)
      @batch.requests = (1..5).map { |_| create(:request_suitable_for_starting, request_type: @batch.pipeline.request_types.last) }
    end

    context 'for completion' do
      setup do
        @batch.start!(@user)
      end

      should 'add errors if there are untagged target asset aliquots' do
        @batch.requests.map(&:target_asset).map(&:untag!)

        assert_raise(ActiveRecord::RecordInvalid) do
          @batch.complete!(@user)
        end

        assert(!@batch.errors.empty?, 'There are no errors on the batch')
      end

      should 'not error if all of the target asset aliquots are tagged' do
        @batch.requests.each_with_index { |r, i| create(:tag, map_id: i).tag!(r.target_asset) }
        @batch.complete!(@user)

        assert(@batch.errors.empty?, 'There are errors on the batch')
      end
    end
  end
end
