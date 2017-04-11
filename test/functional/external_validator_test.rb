# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2015 Genome Research Ltd.

require 'test_helper'

class ExternalValidatorTest < ActiveSupport::TestCase
  context 'A submission with a validated request type' do
    setup do
      @validated_request_type = FactoryGirl.create :validated_request_type
      @assets = [create(:sample_tube)]
      # We don't want to trigger validation just yet!
      @order = FactoryGirl.build(:order, request_types: [@validated_request_type.id], assets: @assets)
      @sample = @assets.first.aliquots.first.sample
    end

    context 'with invalid samples' do
      setup do
        @sample.sample_metadata.sample_taxon_id = '1502'
        @sample.save!
      end

      should 'should be invalid' do
        assert !@order.valid?
        assert_equal ["Samples should have taxon_id 9606: problems with #{@sample.sanger_sample_id}."], @order.errors.full_messages
      end
    end

    context 'with valid samples' do
      setup do
        @sample.sample_metadata.sample_taxon_id = '9606'
        @sample.save!
      end

      should 'should be valid' do
        assert_equal [], @order.errors.full_messages
        assert @order.valid?
      end
    end
  end
end
