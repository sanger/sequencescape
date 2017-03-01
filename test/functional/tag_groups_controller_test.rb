# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2015 Genome Research Ltd.

require 'test_helper'
require 'tag_groups_controller'

class TagGroupsControllerTest < ActionController::TestCase
  context 'tag groups' do
    setup do
      @controller = TagGroupsController.new
      @request    = ActionController::TestRequest.new
      @response   = ActionController::TestResponse.new
      @user = FactoryGirl.create :admin
      session[:user] = @user.id
      @tag_group = FactoryGirl.create :tag_group
    end
    should_require_login

    context '#create' do
      context 'with no tags' do
        setup do
          @taggroup_count = TagGroup.count
          @tag_count =  Tag.count
          post :create, tag_group: { name: 'new tag group' }
        end

        should 'change TagGroup count by 1' do
          assert_equal 1,  TagGroup.count - @taggroup_count, 'Expected TagGroup count to change by 1'
        end
        should 'change Tag.count by 0' do
          assert_equal 0,  Tag.count - @tag_count, 'Expected Tag.count to change by 0'
        end
        should respond_with :redirect
        should set_flash.to(/created/)
      end
      context 'with 2 tag' do
        setup do
          @taggroup_count = TagGroup.count
          @tag_count =  Tag.count
          post :create, tag_group: { name: 'new tag group' }, tags: {  '7' => { 'map_id' => '8', 'oligo' => 'AAA' }, '5' => { 'map_id' => '6', 'oligo' => 'CCC' } }
        end
        should 'change TagGroup.count by 1' do
          assert_equal 1,  TagGroup.count - @taggroup_count, 'Expected TagGroup.count to change by 1'
        end
        should 'change Tag.count by 2' do
          assert_equal 2,  Tag.count - @tag_count, 'Expected Tag.count to change by 2'
        end
        should respond_with :redirect
        should set_flash.to(/created/)
      end

      context 'with 4 tags where 2 have empty oligos' do
        setup do
          @taggroup_count = TagGroup.count
          @tag_count =  Tag.count
          post :create, tag_group: { name: 'new tag group' }, tags: {  '7' => { 'map_id' => '8', 'oligo' => 'AAA' }, '1' => { 'map_id' => '1', 'oligo' => '' }, '5' => { 'map_id' => '6', 'oligo' => 'CCC' }, '9' => { 'map_id' => '9' } }
        end

        should 'change TagGroup.count by 1' do
          assert_equal 1,  TagGroup.count - @taggroup_count, 'Expected TagGroup.count to change by 1'
        end
        should 'change Tag.count by 2' do
          assert_equal 2,  Tag.count - @tag_count, 'Expected Tag.count to change by 2'
        end
        should respond_with :redirect
        should set_flash.to(/created/)
      end
    end

    context '#edit' do
      setup do
        @taggroup_count = TagGroup.count
        @tag_count = Tag.count
        get :edit, id: @tag_group.id
      end
      should respond_with :success
      should 'change TagGroup.count by 0' do
        assert_equal 0,  TagGroup.count - @taggroup_count, 'Expected TagGroup.count to change by 0'
      end
      should 'change Tag.count by 0' do
        assert_equal 0,  Tag.count - @tag_count, 'Expected Tag.count to change by 0'
      end
    end

    context '#update' do
      setup do
        @taggroup_count = TagGroup.count
        @tag_count = Tag.count
        put :update, id: @tag_group.id, tag_group: { name: 'update name' }
      end
      should set_flash.to(/updated/)
      should 'change TagGroup.count by 0' do
        assert_equal 0,  TagGroup.count - @taggroup_count, 'Expected TagGroup.count to change by 0'
      end
      should 'change Tag.count by 0' do
        assert_equal 0,  Tag.count - @tag_count, 'Expected Tag.count to change by 0'
      end
      should respond_with :redirect
      should 'set name' do
        assert_equal 'update name', TagGroup.find(@tag_group.id).name
      end
    end
  end
end
