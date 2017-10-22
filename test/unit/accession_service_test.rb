# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2013,2015 Genome Research Ltd.

require File.dirname(__FILE__) + '/../test_helper'

class AccessionServiceTest < ActiveSupport::TestCase
  def assert_tag(tag_label, value)
    acc = Accessionable::Sample.new(@sample)
    tag = acc.tags.detect { |tag| tag.label == tag_label }
    assert tag, "Could not find #{tag} in #{acc.tags.map(&:label).join(',')}"
    subject_tag = { tag: tag.label, value: tag.value }
    assert_equal({ tag: tag_label, value: value }, subject_tag)
  end

  # temporary test for hotfix
  context 'A sample with a strain' do
    setup do
      @study = create :open_study, accession_number: 'accss'
      @sample = create :sample, studies: [@study]
      @sample.sample_metadata.sample_strain_att = 'my strain'
    end

    should 'expose strain in ERA xml' do
      assert_tag('strain', 'my strain')
    end
  end

  context 'A sample with a gender' do
    setup do
      @study = create :managed_study, accession_number: 'accss'
      @sample = create :sample, studies: [@study]
      @sample.sample_metadata.gender = 'male'
    end

    should 'expose gender in EGA xml' do
      assert_tag('gender', 'male')
    end
  end

  context 'A sample with a donor_id' do
    setup do
      @study = create :managed_study, accession_number: 'accss'
      @sample = create :sample, studies: [@study]
      @sample.sample_metadata.donor_id = '123456789'
    end

    should 'expose donor_id as subject_id in EGA xml' do
      assert_tag('subject_id', '123456789')
    end

    should 'dupe test' do
      assert_tag('subject_id', '123456789')
    end
  end
end
