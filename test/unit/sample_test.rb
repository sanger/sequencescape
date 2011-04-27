require "test_helper"

class Sample
  def move(study_from, study_to, asset_group, new_assets_name, current_user, submission_to)
    study_to.take_sample(self, study_to, current_user, nil)
  end
end
class SampleTest < ActiveSupport::TestCase
  context "A Sample" do

    should_have_many :study_samples
    should_have_many :studies, :through => :study_samples

    context "move a Sample" do
      setup do
        @study_from = Factory :study
        @study_to   = Factory :study
        @sample_from = Factory :sample
        @workflow = Factory :submission_workflow
        @new_assets_name = ""
        @current_user = Factory :user

        @asset_1 = Factory :asset, :name => @sample_from.name, :material_id => @sample_from.id
        
        @asset_group = Factory :asset_group, :name => "not mx"
        @asset_group_asset = Factory :asset_group_asset, :asset_id => @asset_1.id, :asset_group_id => @asset_group.id


        @request_type_1 = Factory :request_type, :name => "request type 1"
        @request_type_2 = Factory :request_type, :name => "request type 2"
        @request_type_3 = Factory :request_type, :name => "Pair end sequencing"

        @request_type_ids = [@request_type_1.id, @request_type_3.id]

        @request_options = {"read_length"=>"108", "fragment_size_required_from"=>"150", "fragment_size_required_to"=>"200"}

        @submission_to = Factory :submission, :study => @study_to, :workflow => @workflow, :assets => [ @asset_1 ],
                         :request_types => @request_type_ids, :request_options => @request_options

      end

      context "has a submission_to and without submission_from" do
        should "return failed error" do
          @sample_from.move(@study_from, @study_to, @asset_group, @new_assets_name, @current_user, @submission_to.id)
          assert_equal @sample_from.errors.full_messages[0], "Move: Study  #{@study_to.id} has a submission. The best way is create a new asset and after create a new submission."
        end
      end
      
      context "With submissions with different request types" do
        setup do
          @request_type_ids_from = [@request_type_2.id, @request_type_3.id]
          @item = Factory :item
          @submission_from_1 = Factory :submission, :study => @study_from, :workflow => @workflow, :assets => [ @asset_1 ],
                           :request_types => @request_type_ids_from, :request_options => @request_options
          @request = Factory :request, :sample => @sample_from, :submission => @submission_from_1, :request_type => @request_type1, :study => @study_from, :workflow => @workflow, :item => @item
        end                                         
        should "return failed" do
          @sample_from.move(@study_from, @study_to, @asset_group, @new_assets_name, @current_user, @submission_to.id)
          assert_equal @sample_from.errors.full_messages[0], "Move: The submissions are different. Please, check this information."
        end
      end

      context "With several assets" do
        setup do
          @new_assets_name = "Test_1"
          @asset_from_2 = Factory :asset, :name => @sample_from.name, :material_id => @sample_from.id
          @sample_tube_1 = Factory :sample_tube, :name => @sample_from.name, :material_id => @sample_from.id
          @sample_tube_1 = Factory :sample_tube, :name => @sample_from.name, :material_id => @sample_from.id
        end                                         
        should "return failed" do
          @sample_from.move(@study_from, @study_to, @asset_group, @new_assets_name, @current_user, 0)
          assert_equal @sample_from.errors.full_messages[0], "Move: This sample has several assets. We could NOT move this sample."
        end
      end
      
      context "only valid assets and without submissions" do
        setup do
          @sample_from_ok = Factory :sample
          @asset_from = Factory :asset, :name => @sample_from_ok.name, :material_id => @sample_from_ok.id
          @asset_group_from_new = Factory :asset_group, :name => "Asset_Sample_New"
          @asset_group_asset_from = Factory :asset_group_asset, :asset_id => @asset_from.id, :asset_group_id => @asset_group_from_new.id

          @sample_to = Factory :sample         
          @asset_to = Factory :asset, :name => @sample_to.name, :material_id => @sample_to.id
          @asset_group_to_new = Factory :asset_group, :name => "Asset_Sample"
          @asset_group_asset_to = Factory :asset_group_asset, :asset_id => @asset_to.id, :asset_group_id => @asset_group_to_new.id

        end

        should "return true" do
          @result = @sample_from_ok.move(@study_from, @study_to, @asset_group_to_new, @new_assets_name, @current_user, "0")
          assert_equal true, @result
          assert_equal @asset_group_to_new.id, @sample_from_ok.assets.first.asset_group_assets.first.asset_group_id
        end
      end      

      context  "With Study_from with submission and New assets or assets without submission" do
        setup do
          @sample_from_ok = Factory :sample
          @asset_from = Factory :asset, :name => @sample_from_ok.name, :material_id => @sample_from_ok.id
          @asset_group_from_new = Factory :asset_group, :name => "Asset_Sample_From"
          @asset_group_asset_from = Factory :asset_group_asset, :asset_id => @asset_from.id, :asset_group_id => @asset_group_from_new.id

          @sample_to = Factory :sample
          @asset_to = Factory :asset, :name => @sample_to.name, :material_id => @sample_to.id
          @asset_group_to_new = Factory :asset_group, :name => "Asset_Sample_To"
          @asset_group_asset_to = Factory :asset_group_asset, :asset_id => @asset_to.id, :asset_group_id => @asset_group_to_new.id

          @request_type_ids_from = [@request_type_2.id, @request_type_3.id]
          @item = Factory :item
          @submission_from_1 = Factory :submission, :study => @study_from, :workflow => @workflow, :assets => [ @asset_from ],
                           :request_types => @request_type_ids_from, :request_options => @request_options
          @request = Factory :request, :sample => @sample_from_ok, :submission => @submission_from_1, :request_type => @request_type1, :study => @study_from, :workflow => @workflow, :item => @item
        end

        should "return true" do
          @result = @sample_from_ok.move(@study_from, @study_to, @asset_group_to_new, @new_assets_name, @current_user, "0")
          @new_sub_to = Submission.last
          asset_submission_to = @new_sub_to.assets
          assert_equal true, @result
          #the assets of submission_from is now in submission_to
          assert_equal asset_submission_to, [ @asset_from ]
          #the assets of submission_from is empty. @submission_from_1
          @submission_from_1.reload
          assert_equal [], @submission_from_1.assets
          #check link about AssetGroup
          assert_equal @asset_group_to_new.id, @sample_from_ok.assets.first.asset_group_assets.first.asset_group_id
        end
      end      
    

      context  "With 2 submissions, with same requests" do
        setup do
          @sample_from_ok = Factory :sample
          @asset_from = Factory :asset, :name => @sample_from_ok.name, :material_id => @sample_from_ok.id
          @asset_group_from_new = Factory :asset_group, :name => "Asset_Sample_From"
          @asset_group_asset_from = Factory :asset_group_asset, :asset_id => @asset_from.id, :asset_group_id => @asset_group_from_new.id

          @sample_to = Factory :sample
          @asset_to = Factory :asset, :name => @sample_to.name, :material_id => @sample_to.id
          @asset_group_to_new = Factory :asset_group, :name => "Asset_Sample_To"
          @asset_group_asset_to = Factory :asset_group_asset, :asset_id => @asset_to.id, :asset_group_id => @asset_group_to_new.id
          
          @request_type_ids_both = [@request_type_2.id, @request_type_3.id]
          @item = Factory :item
          @submission_from_1 = Factory :submission, :study => @study_from, :workflow => @workflow, :assets => [ @asset_from ],
                           :request_types => @request_type_ids_both, :request_options => @request_options
          @request = Factory :request, :sample => @sample_from_ok, :submission => @submission_from_1, :request_type => @request_type1, :study => @study_from, :workflow => @workflow, :item => @item

          @item_to = Factory :item
          @submission_to_1 = Factory :submission, :study => @study_to, :workflow => @workflow, :assets => [ @asset_to ],
                             :request_types => @request_type_ids_both, :request_options => @request_options
          @request = Factory :request, :sample => @sample_to, :submission => @submission_to_1, :request_type => @request_type1, :study => @study_to, :workflow => @workflow, :item => @item_to
        end

        should "return true" do
          @result = @sample_from_ok.move(@study_from, @study_to, @asset_group_to_new, @new_assets_name, @current_user, @submission_to_1.id)
          assert_equal true, @result
          @submission_from_1.reload
          @submission_to_1.reload
          # the assets of submission_from is now in submission_to
          assert_equal @submission_to_1.assets, [ @asset_to, @asset_from ]
          # the assets of submission_from is empty. @submission_from_1
          assert_equal [], @submission_from_1.assets
          #check link about AssetGroup
          assert_equal @asset_group_to_new.id, @sample_from_ok.assets.first.asset_group_assets.first.asset_group_id
        end
      end      
    end

    context "add assets to asset_group" do
      setup do
        @sample_base = Factory :sample

        @asset = Factory :asset, :name => @sample_base.name, :material_id => @sample_base.id
        @asset_group = Factory :asset_group, :name => "Asset_Sample_New"
      end

      should "return true" do
        assert_equal @sample_base.assets.first.asset_groups, []
        @result = @sample_base.add_assets_to_asset_group(@asset_group)
        @sample_base.reload
        assert_equal @sample_base.assets.first.asset_groups.first, @asset_group
      end
    end

    context "remove assets from asset_group" do
      setup do
        @sample_base = Factory :sample
        @asset_from = Factory :asset, :name => @sample_base.name, :material_id => @sample_base.id
        @asset_group_from_new = Factory :asset_group, :name => "Asset_Sample_New"
        @asset_group_asset_from = Factory :asset_group_asset, :asset_id => @asset_from.id, :asset_group_id => @asset_group_from_new.id

      end

      should "return true" do
        assert_equal @sample_base.assets.first.asset_groups.first, @asset_group_from_new
        @result = @sample_base.remove_assets_from_asset_group
        @sample_base.reload
        assert_equal @sample_base.assets.first.asset_groups, []
      end
    end

    context "#accession_number?" do
      setup do
        @sample = Factory :sample
      end
      context "with nil accession number" do
        setup do
          @sample.sample_metadata.sample_ebi_accession_number = nil
        end
        should "return false" do
          assert ! @sample.accession_number?
        end
      end
      context "with a blank accession number" do
        setup do
          @sample.sample_metadata.sample_ebi_accession_number = ''
        end
        should "return false" do
          assert ! @sample.accession_number?
        end
      end
      context "with a valid accession number" do
        setup do
          @sample.sample_metadata.sample_ebi_accession_number = 'ERS00001'
        end
        should "return true" do
          assert @sample.accession_number?
        end
      end
    end
  end
end
