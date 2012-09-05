require "test_helper"

class SampleRegistrarTest < ActiveSupport::TestCase
  context 'SampleRegistrar' do
    setup do
      @study, @user = Factory(:study), Factory(:user)
    end

    context 'registering a sample alone' do
      setup do
        SampleRegistrar.create!(
          :asset_group_helper => SampleRegistrar::AssetGroupHelper.new,
          :study => @study,
          :user  => @user,
          :sample_attributes => { :name => 'valid_sample' },
          :asset_group_name  => ''
        )
      end

      should_change('Sample.count', :by => 1)     { Sample.count          }
      should_change('SampleTube.count', :by => 1) { SampleTube.count      }
      should_not_change('AssetGroup.count')       { AssetGroup.count      }
      should_not_change('SampleRegistrar.count')  { SampleRegistrar.count }

      should 'put the sample in the sample tube' do
        assert_equal(Sample.last, SampleTube.last.primary_aliquot.sample)
      end

      should 'set the sample tube name to the sample name' do
        assert_equal(Sample.last.name, SampleTube.last.name)
      end

      should 'set the barcode on the sample tube based on the ID' do
        sample_tube = SampleTube.last
        assert_equal(sample_tube.id.to_s, sample_tube.barcode)
      end

      should 'put the sample into the study' do
        @study.reload
        assert_contains(@study.samples, Sample.last)
      end

      should 'make the user the owner of the sample' do
        assert(@user.owner?(Sample.last), 'User is not the owner of the sample')
      end
    end

    context 'registering a sample within an asset group' do
      context 'when the asset group does not exist' do
        setup do
          SampleRegistrar.create!(
            :asset_group_helper => SampleRegistrar::AssetGroupHelper.new,
            :study => @study,
            :user  => @user,
            :sample_attributes => { :name => 'valid_sample' },
            :asset_group_name  => 'asset_group_with_one_sample'
          )
        end

        should_change('AssetGroup.count', :by => 1) { AssetGroup.count }

        should 'put the sample tube into the asset groups' do
          assert_contains(AssetGroup.last.assets, SampleTube.last)
        end
      end

      context 'when the asset group already exists' do
        setup do
          Factory(:asset_group, :name => 'asset_group_with_one_sample')
        end

        # NOTE: This structure is required so that the 'should_not_change' statement succeeds.
        # Put merge this context and the parent one and you'll register the Factory(:asset_group)
        # construction!
        context 'the actual test should give you an error. No Samples inserted.' do
          setup do
            assert_raise(ActiveRecord::RecordInvalid) do
              SampleRegistrar.create!(
                :asset_group_helper => SampleRegistrar::AssetGroupHelper.new,
                :study => @study,
                :user  => @user,
                :sample_attributes => { :name => 'valid_sample' },
                :asset_group_name  => 'asset_group_with_one_sample'
              )
            end
          end

          should_not_change('Sample.count')     { Sample.count }
        end
      end
    end

    context 'registering a sample within a sample tube' do
      setup do
        SampleRegistrar.create!(
          :asset_group_helper => SampleRegistrar::AssetGroupHelper.new,
          :study => @study,
          :user  => @user,
          :sample_attributes => { :name => 'valid_sample' },
          :sample_tube_attributes => { :two_dimensional_barcode => 'XX12345' }
        )
      end

      should 'set the barcode to the 2D barcode' do
        assert_equal('12345', SampleTube.last.barcode)
      end
    end

    should_belong_to :user
    should_belong_to :study
    should_belong_to :sample
    should_belong_to :sample_tube

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
                :ignore => '1',
                :study  => @study,
                :user   => @user,
                :sample_attributes => { :name => 'valid_sample' }
              }
            ])
          end
        end
      end

      context 'ignores any samples to be registered' do
        setup do
          SampleRegistrar.register!([
            {
              :ignore => '1',
              :study  => @study,
              :user   => @user,
              :asset_group_name => 'ignored_asset_group',
              :sample_attributes => { :name => 'ignored_sample' }
            },
            {
              :study  => @study,
              :user   => @user,
              :sample_attributes => { :name => 'valid_sample' }
            }
          ])
        end

        should_not_change('SampleRegistrar.count')  { SampleRegistrar.count }
        should_change('Sample.count', :by => 1)     { Sample.count          }
        should_change('SampleTube.count', :by => 1) { SampleTube.count      }
        should_not_change('AssetGroup.count')       { AssetGroup.count      }

        should 'not registered the ignored sample' do
          assert_nil(Sample.find_by_name('ignored_sample'))
        end
      end

      context 'registers multiple samples correctly' do
        setup do
          SampleRegistrar.register!([
            {
              :study => @study,
              :user  => @user,
              :sample_attributes => { :name => 'valid_sample_1' },
              :asset_group_name  => 'asset_group_1'
            },
            {
              :study => @study,
              :user  => @user,
              :sample_attributes => { :name => 'valid_sample_2' },
              :asset_group_name  => 'asset_group_2'
            },
            {
              :ignore => '1',
              :study  => @study,
              :user   => @user,
              :sample_attributes => { :name => 'ignored_sample_1' },
              :asset_group_name  => 'asset_group_1'
            },
            {
              :study => @study,
              :user  => @user,
              :sample_attributes => { :name => 'valid_sample_3' },
              :asset_group_name  => 'asset_group_1'
            },
            {
              :study => @study,
              :user  => @user,
              :sample_attributes => { :name => 'valid_sample_4' },
            },
          ])
        end

        should_not_change('SampleRegistrar.count')  { SampleRegistrar.count }
        should_change('Sample.count', :by => 4)     { Sample.count          }
        should_change('SampleTube.count', :by => 4) { SampleTube.count      }
        should_change('AssetGroup.count', :by => 2) { AssetGroup.count      }

        should 'put samples 1 and 3 into asset group 1' do
          group = AssetGroup.find_by_name('asset_group_1')
          assert_contains(group.assets, SampleTube.find_by_name('valid_sample_1'))
          assert_contains(group.assets, SampleTube.find_by_name('valid_sample_3'))
        end

        should 'put sample 2 into asset group 2' do
          assert_contains(AssetGroup.find_by_name('asset_group_2').assets, SampleTube.find_by_name('valid_sample_2'))
        end

        should 'not have created sample 3' do
          assert_nil(Sample.find_by_name('ignored_sample_1'))
        end
      end
    end
  end
end
