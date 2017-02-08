# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2014,2015 Genome Research Ltd.

require 'test_helper'

class SampleRegistrarTest < ActiveSupport::TestCase
  context 'SampleRegistrar' do
    setup do
      @study, @user = create(:study), create(:user)
    end

    context 'registering a sample alone' do
      setup do
        @initial_agc =  AssetGroup.count
        @initial_src =  SampleRegistrar.count
        @sample_count = Sample.count
        @sampletube_count = SampleTube.count
        SampleRegistrar.create!(
          asset_group_helper: SampleRegistrar::AssetGroupHelper.new,
          study: @study,
          user: @user,
          sample_attributes: { name: 'valid_sample' },
          asset_group_name: ''
        )
      end

      should 'change Sample.count by 1' do
        assert_equal 1,  Sample.count           - @sample_count, 'Expected Sample.count to change by 1'
      end

      should 'change SampleTube.count by 1' do
        assert_equal 1,  SampleTube.count       - @sampletube_count, 'Expected SampleTube.count to change by 1'
      end
      should 'not change AssetGroup.count' do
        assert_equal @initial_agc,  AssetGroup.count
      end

      should 'not change SampleRegistrar.count' do
        assert_equal @initial_src,  SampleRegistrar.count
      end

      should 'put the sample in the sample tube' do
        assert_equal(Sample.last, SampleTube.last.primary_aliquot.sample)
      end

      should 'set the sample tube name to the sample name' do
        assert_equal(Sample.last.name, SampleTube.last.name)
      end

      should 'set the barcode on the sample tube based on the AssetBarcode service' do
        sample_tube = SampleTube.last
        assert_equal(AssetBarcode.last.id.to_s, sample_tube.barcode)
      end

      should 'put the sample into the study' do
        @study.reload
        assert_contains(@study.samples, Sample.last)
      end

      should 'put the aliquots into the study' do
        assert_equal @study, SampleTube.last.aliquots.first.study
      end

      should 'make the user the owner of the sample' do
        assert(@user.owner?(Sample.last), 'User is not the owner of the sample')
      end
    end

    context 'registering a sample within an asset group' do
      context 'when the asset group does not exist' do
        setup do
          @assetgroup_count = AssetGroup.count
          SampleRegistrar.create!(
            asset_group_helper: SampleRegistrar::AssetGroupHelper.new,
            study: @study,
            user: @user,
            sample_attributes: { name: 'valid_sample' },
            asset_group_name: 'asset_group_with_one_sample'
          )
        end

        should 'change AssetGroup.count by 1' do
          assert_equal 1, AssetGroup.count - @assetgroup_count, 'Expected AssetGroup.count to change by 1'
        end

        should 'put the sample tube into the asset groups' do
          assert_contains(AssetGroup.last.assets, SampleTube.last)
        end
      end

      context 'when the asset group already exists' do
        setup do
          create(:asset_group, name: 'asset_group_with_one_sample')
        end

        # NOTE: This structure is required so that the 'should_not_change' statement succeeds.
        # Put merge this context and the parent one and you'll register the create(:asset_group)
        # construction!
        context 'the actual test should give you an error. No Samples inserted.' do
          setup do
            @initial_sc = Sample.count
            assert_raise(ActiveRecord::RecordInvalid) do
              SampleRegistrar.create!(
                asset_group_helper: SampleRegistrar::AssetGroupHelper.new,
                study: @study,
                user: @user,
                sample_attributes: { name: 'valid_sample' },
                asset_group_name: 'asset_group_with_one_sample'
              )
            end
          end

          should 'not change Sample.count' do
            assert_equal @initial_sc, Sample.count
          end
        end
      end
    end

    context 'registering a sample within a sample tube' do
      setup do
        SampleRegistrar.create!(
          asset_group_helper: SampleRegistrar::AssetGroupHelper.new,
          study: @study,
          user: @user,
          sample_attributes: { name: 'valid_sample' },
          sample_tube_attributes: { two_dimensional_barcode: 'XX12345' }
        )
      end
    end

    should belong_to :user
    should belong_to :study
    should belong_to(:sample).validate(true)
    should belong_to(:sample_tube).validate(true)

    context '.register!' do
      context 'raises an error if no samples are specified' do
        should 'raise when there are no samples specified' do
          assert_raise(SampleRegistrar::NoSamplesError) do
            SampleRegistrar.register!([])
          end
        end

        should 'raise when all samples are ignored' do
          assert_raise(SampleRegistrar::NoSamplesError) do
            SampleRegistrar.register!([
              {
                ignore: '1',
                study: @study,
                user: @user,
                sample_attributes: { name: 'valid_sample' }
              }
            ])
          end
        end
      end

      context 'ignores any samples to be registered' do
        setup do
          @sample_count = Sample.count
          @initial_src =  SampleRegistrar.count
          @initial_agc =  AssetGroup.count
          @sampletube_count = SampleTube.count
          SampleRegistrar.register!([
            {
              ignore: '1',
              study: @study,
              user: @user,
              asset_group_name: 'ignored_asset_group',
              sample_attributes: { name: 'ignored_sample' }
            },
            {
              study: @study,
              user: @user,
              sample_attributes: { name: 'valid_sample' }
            }
          ])
        end

        should 'not change SampleRegistrar.count' do
          assert_equal @initial_src, SampleRegistrar.count
        end

        should 'change Sample.count by 1' do
          assert_equal 1,  Sample.count           - @sample_count, 'Expected Sample.count to change by 1'
        end

        should 'change SampleTube.count by 1' do
          assert_equal 1,  SampleTube.count       - @sampletube_count, 'Expected SampleTube.count to change by 1'
        end
        should 'not change AssetGroup.count' do
          assert_equal @initial_agc, AssetGroup.count
        end

        should 'not registered the ignored sample' do
          assert_nil(Sample.find_by(name: 'ignored_sample'))
        end
      end

      context 'registers multiple samples correctly' do
        setup do
          @initial_sample_registrar = SampleRegistrar.count
          @sample_count = Sample.count
          @sampletube_count =  SampleTube.count
          @assetgroup_count =  AssetGroup.count
          SampleRegistrar.register!([
            {
              study: @study,
              user: @user,
              sample_attributes: { name: 'valid_sample_1' },
              asset_group_name: 'asset_group_1'
            },
            {
              study: @study,
              user: @user,
              sample_attributes: { name: 'valid_sample_2' },
              asset_group_name: 'asset_group_2'
            },
            {
              ignore: '1',
              study: @study,
              user: @user,
              sample_attributes: { name: 'ignored_sample_1' },
              asset_group_name: 'asset_group_1'
            },
            {
              study: @study,
              user: @user,
              sample_attributes: { name: 'valid_sample_3' },
              asset_group_name: 'asset_group_1'
            },
            {
              study: @study,
              user: @user,
              sample_attributes: { name: 'valid_sample_4' },
            },
          ])
        end

        should 'not change SampleRegistrar.count' do
          assert_equal @initial_sample_registrar, SampleRegistrar.count
        end

        should 'change Sample.count by 4' do
          assert_equal 4,  Sample.count           - @sample_count, 'Expected Sample.count to change by 4'
        end

        should 'change SampleTube.count by 4' do
          assert_equal 4,  SampleTube.count       - @sampletube_count, 'Expected SampleTube.count to change by 4'
        end

        should 'change AssetGroup.count by 2' do
          assert_equal 2,  AssetGroup.count       - @assetgroup_count, 'Expected AssetGroup.count to change by 2'
        end

        should 'put samples 1 and 3 into asset group 1' do
          group = AssetGroup.find_by(name: 'asset_group_1')
          assert_contains(group.assets, SampleTube.find_by(name: 'valid_sample_1'))
          assert_contains(group.assets, SampleTube.find_by(name: 'valid_sample_3'))
        end

        should 'put sample 2 into asset group 2' do
          assert_contains(AssetGroup.find_by(name: 'asset_group_2').assets, SampleTube.find_by(name: 'valid_sample_2'))
        end

        should 'not have created sample 3' do
          assert_nil(Sample.find_by(name: 'ignored_sample_1'))
        end
      end
    end
  end
end
