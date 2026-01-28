# frozen_string_literal: true

require 'test_helper'

class SampleTest < ActiveSupport::TestCase
  context 'A Sample' do
    should have_many :study_samples
    should have_many :studies

    context 'when used in older assets' do
      setup do
        @sample = create(:sample)
        @tube_a = create(:empty_library_tube)
        @tube_b = create(:empty_sample_tube)

        create(:aliquot, sample: @sample, receptacle: @tube_b)
        create(:aliquot, sample: @sample, receptacle: @tube_a)
      end

      should 'have the first tube it was added to as a primary asset' do
        assert_equal @sample.reload.primary_receptacle, @tube_b.receptacle
      end
    end
  end
end
