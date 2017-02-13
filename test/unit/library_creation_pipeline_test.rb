# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2015 Genome Research Ltd.

require 'test_helper'

class LibraryCreationPipelineTest < ActiveSupport::TestCase
  context 'Pipeline' do
    setup do
      @pipeline = create :library_creation_pipeline, name: 'Library creation pipeline'
    end

    should 'return true for library_creation?' do
      assert @pipeline.library_creation?
    end

    should 'return false for genotyping?' do
      assert !@pipeline.genotyping?
    end

    should 'return false for pulldown?' do
      assert !@pipeline.pulldown?
    end

    should 'return false for prints_a_worksheet_per_task?' do
      assert !@pipeline.prints_a_worksheet_per_task?
    end

    context '#create_batch_from_plate(assets)' do
    end
  end
end
