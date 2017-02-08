# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2013,2015 Genome Research Ltd.

require 'test_helper'

class RequestcreateTest < ActiveSupport::TestCase
  context 'Requestcreate' do
    context '.copy_request' do
      setup do
        @project = create(:project)
        @project.project_metadata.update_attributes!(budget_division: BudgetDivision.create!(name: 'Test'))
        @order = create(:order, project: @project)
        @request = create(:request, request_type: create(:request_type), project: @project, asset: create(:sample_tube), target_asset: create(:well))
      end

      context 'without quotas' do
        setup do
          @project.update_attributes!(enforce_quotas: false)
          @copy = RequestFactory.copy_request(@request)
        end

        should 'have the same request type' do
          assert_equal @request.request_type, @copy.request_type
        end

        should 'have no target asset' do
          assert_nil @copy.target_asset
        end

        should 'be pending' do
          assert_equal 'pending', @copy.state
        end
      end

      context 'with quotas' do
        setup do
          @project.update_attributes!(enforce_quotas: true)
        end

        should 'not fail' do
          RequestFactory.copy_request(@request)
        end
      end
    end
  end

  context '.create_assets_requests' do
    setup do
      @study  = create(:study)
      @assets = [
        create(:sample_tube, study: nil, project: nil),
        create(:sample_tube, study: nil, project: nil)
      ]

      RequestFactory.create_assets_requests(@assets, @study)
    end

    should 'have all create asset requests as passed' do
      assert_equal ['passed'], RequestType.find_by(key: 'create_asset').requests.map(&:state).uniq
    end

    should 'have the study on all requests' do
      assert_equal [@study.id], RequestType.find_by(key: 'create_asset').requests.map(&:study_id).uniq
    end

    should 'have the asset IDs' do
      assert_equal @assets.map(&:id).sort, RequestType.find_by(key: 'create_asset').requests.map(&:asset_id).sort
    end
  end
end
