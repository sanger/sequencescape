# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2015 Genome Research Ltd.

require 'test_helper'

class Studies::AssetGroupsControllerTest < ActionController::TestCase
  @assetgroup_count = AssetGroup.count
  @study_count = Study.count

  context 'Studies AssetGroups' do
    setup do
      @assetgroup_count_a = AssetGroup.count
      @study_count_a = Study.count
      @controller = Studies::AssetGroupsController.new
      @request    = ActionController::TestRequest.new
      @response   = ActionController::TestResponse.new
      @user = FactoryGirl.create :user
      session[:user] = @user.id
      @controller.stubs(:logged_in?).returns(@user)
      @study = FactoryGirl.create :study
      @asset_group = FactoryGirl.create :asset_group
    end

    ['index', 'new'].each do |controller_method|
      context "##{controller_method}" do
        setup do
          @assetgroup_count = AssetGroup.count
          @study_count = Study.count
          get controller_method, study_id: @study.id
        end
        should respond_with :success

        should 'change AssetGroup.count by 0' do
          assert_equal 0,  AssetGroup.count - @assetgroup_count, 'Expected AssetGroup.count to change by 0'
        end
        should 'change Study.count by 0' do
          assert_equal 0,  Study.count - @study_count, 'Expected Study.count to change by 0'
        end
      end
    end

    %w(show edit print printing).each do |controller_method|
      context "##{controller_method}" do
        setup do
          @assetgroup_count = AssetGroup.count
          @study_count = Study.count
          get controller_method, study_id: @study.id, id: @asset_group.id
        end
        should 'change AssetGroup.count by 0' do
          assert_equal 0,  AssetGroup.count - @assetgroup_count, 'Expected AssetGroup.count to change by 0'
        end
        should 'change Study.count by 0' do
          assert_equal 0,  Study.count - @study_count, 'Expected Study.count to change by 0'
        end
      end
    end

    context '#search' do
      context 'should redirect if no query is passed in' do
        setup do
          get :search, study_id: @study.id, id: @asset_group.id
        end

        should respond_with :redirect
      end

      context 'should redirect if it is given a blank query' do
        setup do
          get :search, study_id: @study.id, id: @asset_group.id, q: ''
        end

        should respond_with :redirect
      end

      context 'should redirect if too small a query is passed' do
        setup do
          get :search, study_id: @study.id, id: @asset_group.id, q: 'a'
        end

        should respond_with :redirect
      end

      context 'should suceed with a query longer than 1' do
        setup do
          get :search, study_id: @study.id, id: @asset_group.id, q: 'ab'
        end

        should respond_with :success
      end
    end

    context '#destroy' do
      setup do
        @study_count = Study.count
        @assetgroup_count = AssetGroup.count
        delete :destroy, study_id: @study.id, id: @asset_group.id
      end

      should 'change AssetGroup.count by -1' do
       assert_equal(-1, AssetGroup.count - @assetgroup_count, 'Expected AssetGroup.count to change by -1')
      end

      should 'change Study.count by 0' do
        assert_equal 0,  Study.count - @study_count, 'Expected Study.count to change by 0'
      end

      should respond_with :redirect
    end

    context '#update' do
      setup do
        @assetgroup_count = AssetGroup.count
        @study_count = Study.count
        put :update, study_id: @study.id, id: @asset_group.id, asset_group: { name: 'update name' }
      end

      should set_flash.to(/updated/)

      should 'change AssetGroup.count by 0' do
         assert_equal 0,  AssetGroup.count - @assetgroup_count, 'Expected AssetGroup.count to change by 0'
      end

      should 'change Study.count by 0' do
         assert_equal 0,  Study.count - @study_count, 'Expected Study.count to change by 0'
      end

      should respond_with :redirect

      should 'set name' do
        assert_equal 'update name', AssetGroup.find(@asset_group.id).name
      end
    end

    context '#print_labels' do
      should 'send print request' do
        @user = create :user
        @controller.stubs(:current_user).returns(@user)
        @asset = create :child_plate
        barcode_printer = create :barcode_printer
        LabelPrinter::PmbClient.expects(:get_label_template_by_name).returns('data' => [{ 'id' => 15 }])

        RestClient.expects(:post)

        post :print_labels, printables: { (@asset.id).to_s => 'true' }, printer: barcode_printer.name, id: @asset_group.id, study_id: @study.id
      end
    end
  end
end
