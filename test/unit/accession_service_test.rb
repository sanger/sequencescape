# frozen_string_literal: true

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
      @study = create(:open_study, accession_number: 'accss')
      @sample = create(:sample, studies: [@study])
      @sample.sample_metadata.sample_strain_att = 'my strain'
    end

    should 'expose strain in ERA xml' do
      assert_tag('strain', 'my strain')
    end
  end

  context 'A sample with a gender' do
    setup do
      @study = create(:managed_study, accession_number: 'accss')
      @sample = create(:sample, studies: [@study])
      @sample.sample_metadata.gender = 'male'
    end

    should 'expose gender in EGA xml' do
      assert_tag('gender', 'male')
    end
  end

  context 'A sample with a donor_id' do
    setup do
      @study = create(:managed_study, accession_number: 'accss')
      @sample = create(:sample, studies: [@study])
      @sample.sample_metadata.donor_id = '123456789'
    end

    should 'expose donor_id as subject id in EGA xml' do
      assert_tag('subject id', '123456789')
    end

    should 'dupe test' do
      assert_tag('subject id', '123456789')
    end
  end

  context 'A sample with a country_of_origin' do
    setup do
      @country = create(:insdc_country, name: 'Freedonia')
      @study = create(:managed_study, accession_number: 'accss')
      @sample = create(:sample, studies: [@study])
    end

    context 'with unexistent country' do
      setup { @sample.sample_metadata.country_of_origin = 'Pepe' }
      should 'send the default error value' do
        assert_tag('geographic location (country and/or sea)', 'not provided')
      end
    end

    context 'with no country' do
      should 'send the default error value' do
        assert_tag('geographic location (country and/or sea)', 'not provided')
      end
    end

    context 'with right country' do
      setup { @sample.sample_metadata.country_of_origin = 'Freedonia' }
      should 'send the country name' do
        assert_tag('geographic location (country and/or sea)', 'Freedonia')
      end
    end

    context 'with other defined values for country_of_origin' do
      setup { @sample.sample_metadata.country_of_origin = 'not provided' }
      should 'send the collection date' do
        assert_tag('geographic location (country and/or sea)', 'not provided')
      end
    end

    context 'with missing for country_of_origin' do
      setup { @sample.sample_metadata.country_of_origin = 'missing: endangered species' }
      should 'send the collection date' do
        assert_tag('geographic location (country and/or sea)', 'missing: endangered species')
      end
    end
  end

  context 'A sample with a collection date' do
    setup do
      @study = create(:managed_study, accession_number: 'accss')
      @sample = create(:sample, studies: [@study])
    end

    context 'with unexistent date_of_sample_collection' do
      setup { @sample.sample_metadata.date_of_sample_collection = 'Pepe' }
      should 'send the default error value' do
        assert_tag('collection date', 'not provided')
      end
    end

    context 'with no date_of_sample_collection' do
      should 'send the default error value' do
        assert_tag('collection date', 'not provided')
      end
    end

    context 'with right date_of_sample_collection' do
      setup { @sample.sample_metadata.date_of_sample_collection = '2023-04-25T00:00:00Z' }
      should 'send the collection date' do
        assert_tag('collection date', '2023-04-25T00:00:00Z')
      end
    end

    context 'with other defined values for date_of_sample_collection' do
      setup { @sample.sample_metadata.date_of_sample_collection = 'not provided' }
      should 'send the collection date' do
        assert_tag('collection date', 'not provided')
      end
    end

    context 'with missing for date_of_sample_collection' do
      setup { @sample.sample_metadata.date_of_sample_collection = 'missing: endangered species' }
      should 'send the collection date' do
        assert_tag('collection date', 'missing: endangered species')
      end
    end
  end
end
