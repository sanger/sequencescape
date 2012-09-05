require "test_helper"
require 'tag_groups_controller'

# Re-raise errors caught by the controller.
class TagGroupsController; def rescue_action(e) raise e end; end

class TagGroupsControllerTest < ActionController::TestCase
  context "tag groups" do
    setup do
      @controller = TagGroupsController.new
      @request    = ActionController::TestRequest.new
      @response   = ActionController::TestResponse.new
      @user = Factory :admin
      @controller.stubs(:logged_in?).returns(@user)
      @controller.stubs(:current_user).returns(@user)
      @tag_group = Factory :tag_group
    end
    should_require_login

    context "#create" do
      context "with no tags" do
        setup do
          post :create, :tag_group => {:name=>"new tag group"}
        end
        should_change("TagGroup count", :by => 1) { TagGroup.count }
        should_change("Tag.count", :by => 0) { Tag.count }
        should_respond_with :redirect
        should_set_the_flash_to /created/
      end
      context "with 2 tag" do
        setup do
          post :create, :tag_group => {:name=>"new tag group"}, :tags =>  {  "7"=>{"map_id"=>"8", "oligo"=>"AAA"},  "5"=>{"map_id"=>"6", "oligo"=>"CCC"}}
        end
        should_change("TagGroup.count", :by => 1) { TagGroup.count }
        should_change("Tag.count", :by => 2) { Tag.count }
        should_respond_with :redirect
        should_set_the_flash_to /created/
      end

      context "with 4 tags where 2 have empty oligos" do
        setup do
          post :create, :tag_group => {:name=>"new tag group"}, :tags =>  {  "7"=>{"map_id"=>"8", "oligo"=>"AAA"}, "1"=>{"map_id"=>"1", "oligo"=>""} ,  "5"=>{"map_id"=>"6", "oligo"=>"CCC"},"9"=>{"map_id"=>"9"}}
        end
        should_change("TagGroup.count", :by => 1) { TagGroup.count }
        should_change("Tag.count", :by => 2) { Tag.count }
        should_respond_with :redirect
        should_set_the_flash_to /created/
      end
    end

    context "#edit" do
      setup do
        get :edit, :id => @tag_group.id
      end
      should_respond_with :success
      should_change("TagGroup.count", :by => 0) { TagGroup.count }
      should_change("Tag.count", :by => 0) { Tag.count }
    end

    context "#update" do
      setup do
        put :update, :id => @tag_group.id, :name=>"update name"
      end
      should_set_the_flash_to /updated/
      should_change("TagGroup.count", :by => 0) { TagGroup.count }
      should_change("Tag.count", :by => 0) { Tag.count }
      should_respond_with :redirect
      should "set name" do
        assert "update name", TagGroup.find(@tag_group.id).name
      end
    end
  end
end
