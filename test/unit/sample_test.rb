# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2014,2015 Genome Research Ltd.

require 'test_helper'

class SampleTest < ActiveSupport::TestCase
  context 'A Sample' do
    should have_many :study_samples
    should have_many :studies # , :through => :study_samples

    context 'when used in older assets' do
      setup do
        @sample = create :sample
        @tube_a = create :empty_library_tube
        @tube_b = create :empty_sample_tube

       create(:aliquot, sample: @sample, receptacle: @tube_b)
       create(:aliquot, sample: @sample, receptacle: @tube_a)
      end

      should 'have the first tube it was added to as a primary asset' do
        assert_equal @sample.reload.primary_receptacle, @tube_b
      end
    end

    context '#accession_number?' do
      setup do
        @sample = create :sample
      end
      context 'with nil accession number' do
        setup do
          @sample.sample_metadata.sample_ebi_accession_number = nil
        end
        should 'return false' do
          assert !@sample.accession_number?
        end
      end
      context 'with a blank accession number' do
        setup do
          @sample.sample_metadata.sample_ebi_accession_number = ''
        end
        should 'return false' do
          assert !@sample.accession_number?
        end
      end
      context 'with a valid accession number' do
        setup do
          @sample.sample_metadata.sample_ebi_accession_number = 'ERS00001'
        end
        should 'return true' do
          assert @sample.accession_number?
        end
      end
    end
  end
end
