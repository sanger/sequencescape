require "test_helper"

class AssetGroupTest < ActiveSupport::TestCase
  context "An AssetGroup" do
    setup do
      Study.destroy_all
      @asset1 = mock("Asset 1")
      @asset1.stubs(:id).returns(1)
      @asset2 = mock("Asset 2")
      @asset2.stubs(:id).returns(2)
      @asset3 = mock("Asset 3")
      @asset3.stubs(:id).returns(3)
      @assets = []
      @study = Factory :study
      @asset_group = Factory :asset_group, :study_id => @study.id
      @asset_group.stubs(:assets).returns([@asset1,@asset2])
      #  @asset_group.add_assets(@assets)
    end

    should "return the number of assets" do
      assert_equal 2, @asset_group.assets.size
    end

    should "add to its assets" do
      assert_equal 2, @asset_group.assets.size
      @asset_group.assets << @asset3
      @asset_group.reload
      assert_equal 3, @asset_group.assets.size
    end
  end

  context "Validation" do
    setup do
      Study.destroy_all
      @study = Factory :study

    end
    should "not allow an AssetGroup to be created without a study" do
      assert_raises ActiveRecord::RecordInvalid do
        @asset_group = Factory :asset_group, :study_id => nil
      end
    end

    should "not allow an AssetGroup to be created without a name" do
      assert_raises ActiveRecord::RecordInvalid do
        @asset_group = Factory :asset_group, :name => "", :study_id => @study.id
      end
    end

    should_not_change("AssetGroup.count") { AssetGroup.count }

    should "only allow a name to be used once" do
      Factory :asset_group, :name => "Another-Name", :study_id => @study.id
      assert_raises ActiveRecord::RecordInvalid do
        Factory :asset_group, :name => "Another-Name", :study_id => @study.id
      end
    end

    context "#all_samples_have_accession_numbers?" do
      setup do
        @asset_group = Factory :asset_group
      end
      context "where all samples" do
        setup do
          5.times do |i|
            sample = Factory :sample
            sample.sample_metadata.sample_ebi_accession_number = "ERS00001"
            asset =  Factory :asset, :sample => sample
            @asset_group.assets << asset
            @asset_group.save
          end
        end
        context "have accession nubmers" do
          should "return true" do
            assert_equal 5, @asset_group.assets.size
            assert !@asset_group.assets.first.sample.nil?
            assert @asset_group.all_samples_have_accession_numbers?
          end
        end
        context "except 1 have accession numbers" do
          setup do
            sample = Factory :sample
            sample.sample_metadata.sample_ebi_accession_number = ''
            asset =  Factory :asset,:sample => sample
            @asset_group.assets << asset
            @asset_group.save
          end
          should "return false" do
            assert ! @asset_group.all_samples_have_accession_numbers?
          end
        end
      end
      context "no samples have accession numbers" do
        setup do
          5.times do |i|
            sample = Factory :sample
            sample.sample_metadata.sample_ebi_accession_number = ''
            asset =  Factory :asset, :sample => sample
            @asset_group.assets << asset
            @asset_group.save
          end
        end
        should "return false" do
          assert_equal 5, @asset_group.assets.size
          # TODO: Fix sample
#          assert_equal 1, @asset_group.assets.last.sample.properties.size
          assert_equal false, @asset_group.all_samples_have_accession_numbers?
        end
      end

    end

  end
end
