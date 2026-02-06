# frozen_string_literal: true

require 'test_helper'

class ExternalValidatorTest < ActiveSupport::TestCase
  context 'A submission with a validated request type' do
    setup do
      @validated_request_type = FactoryBot.create(:validated_request_type)
      @assets = [create(:sample_tube)]

      # We don't want to trigger validation just yet!
      @order = FactoryBot.build(:order, request_types: [@validated_request_type.id], assets: @assets)
      @sample = @assets.first.aliquots.first.sample
    end

    context 'with invalid samples' do
      setup do
        @sample.sample_metadata.sample_taxon_id = '1502'
        @sample.save!
      end

      should 'should be invalid' do
        assert_not @order.valid?
        assert_equal ["Samples should have taxon_id 9606: problems with #{@sample.sanger_sample_id}."],
                     @order.errors.full_messages
      end
    end

    context 'with valid samples' do
      setup do
        @sample.sample_metadata.sample_taxon_id = '9606'
        @sample.save!
      end

      should 'should be valid' do
        assert_empty @order.errors.full_messages
        assert_predicate @order, :valid?
      end
    end
  end
end
