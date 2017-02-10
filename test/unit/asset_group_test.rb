# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2015 Genome Research Ltd.

require 'test_helper'

class AssetGroupTest < ActiveSupport::TestCase
  context 'An AssetGroup' do
    setup do
      Study.destroy_all
      @asset1 = mock('Asset 1')
      @asset1.stubs(:id).returns(1)
      @asset1.stubs(:sti_type).returns('Tube')
      @asset1.stubs(:automatic_move?).returns(true)
      @asset2 = mock('Asset 2')
      @asset2.stubs(:id).returns(2)
      @asset2.stubs(:sti_type).returns('Tube')
      @asset3 = mock('Asset 3')
      @asset3.stubs(:id).returns(3)
      @assets = []
      @study = create :study
      @asset_group = create :asset_group, study_id: @study.id
      @asset_group.stubs(:assets).returns([@asset1, @asset2])
    end

    should 'return the number of assets' do
      assert_equal 2, @asset_group.assets.size
    end

    should 'report its asset types' do
      assert_equal ['Tube'], @asset_group.asset_types
    end

    should 'support automatic_move?' do
      assert @asset_group.automatic_move?
    end

    should 'add to its assets' do
      assert_equal 2, @asset_group.assets.size
      @asset_group.assets << @asset3
      @asset_group.reload
      assert_equal 3, @asset_group.assets.size
    end
  end

  context 'A mixed AssetGroup' do
    setup do
      Study.destroy_all
      @asset1 = mock('Asset 1')
      @asset1.stubs(:id).returns(1)
      @asset1.stubs(:sti_type).returns('Tube')
      @asset1.stubs(:automatic_move?)
      @asset2 = mock('Asset 2')
      @asset2.stubs(:id).returns(2)
      @asset2.stubs(:sti_type).returns('Well')
      @assets = []
      @study = create :study
      @asset_group = create :asset_group, study_id: @study.id
      @asset_group.stubs(:assets).returns([@asset1, @asset2])
    end

    should 'report its asset types' do
      assert_equal ['Tube', 'Well'], @asset_group.asset_types
    end

    should 'not support automatic_move?' do
      assert !@asset_group.automatic_move?
    end
  end

  context 'With immovable assets' do
    setup do
      Study.destroy_all
      @asset1 = mock('Asset 1')
      @asset1.stubs(:id).returns(1)
      @asset1.stubs(:sti_type).returns('Tube')
      @asset1.stubs(:automatic_move?).returns(false)
      @asset2 = mock('Asset 2')
      @asset2.stubs(:id).returns(2)
      @asset2.stubs(:sti_type).returns('Tube')
      @assets = []
      @study = create :study
      @asset_group = create :asset_group, study_id: @study.id
      @asset_group.stubs(:assets).returns([@asset1, @asset2])
    end

    should 'not support automatic_move?' do
      assert !@asset_group.automatic_move?
    end
  end

  context 'Validation' do
    setup do
      @ag_count = AssetGroup.count
      Study.destroy_all
      @study = create :study
    end
    should 'not allow an AssetGroup to be created without a study' do
      assert_raises ActiveRecord::RecordInvalid do
        @asset_group = create :asset_group, study_id: nil
      end
    end

    should 'not allow an AssetGroup to be created without a name' do
      assert_raises ActiveRecord::RecordInvalid do
        @asset_group = create :asset_group, name: '', study_id: @study.id
      end
    end

    should 'not change AssetGroup.count' do
      assert_equal AssetGroup.count, @ag_count
    end

    should 'only allow a name to be used once' do
      create :asset_group, name: 'Another-Name', study_id: @study.id
      assert_raises ActiveRecord::RecordInvalid do
        create :asset_group, name: 'Another-Name', study_id: @study.id
      end
    end

    context '#all_samples_have_accession_numbers?' do
      setup do
        @asset_group = create :asset_group
      end
      context 'where all samples' do
        setup do
          5.times do |_i|
            asset = create(:sample_tube)
            asset.primary_aliquot.sample.update_attributes!(sample_metadata_attributes: { sample_ebi_accession_number: 'ERS00001' })
            @asset_group.assets << asset
          end
        end
        context 'have accession nubmers' do
          should 'return true' do
            assert_equal 5, @asset_group.assets.size
            assert !@asset_group.assets.first.primary_aliquot.sample.nil?
            assert @asset_group.all_samples_have_accession_numbers?
          end
        end
        context 'except 1 have accession numbers' do
          setup do
            asset = create(:sample_tube)
            asset.primary_aliquot.sample.update_attributes!(sample_metadata_attributes: { sample_ebi_accession_number: '' })
            @asset_group.assets << asset
          end
          should 'return false' do
            assert !@asset_group.all_samples_have_accession_numbers?
          end
        end
      end
      context 'no samples have accession numbers' do
        setup do
          5.times do |_i|
            asset = create(:sample_tube)
            asset.primary_aliquot.sample.update_attributes!(sample_metadata_attributes: { sample_ebi_accession_number: '' })
            @asset_group.assets << asset
          end
        end
        should 'return false' do
          assert_equal 5, @asset_group.assets.size
          assert_equal false, @asset_group.all_samples_have_accession_numbers?
        end
      end
    end
  end
end
