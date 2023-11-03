# frozen_string_literal: true

require 'test_helper'

class RequestcreateTest < ActiveSupport::TestCase
  context 'Requestcreate' do
    context '.copy_request' do
      setup do
        @project = create(:project)
        @project.project_metadata.update!(budget_division: BudgetDivision.create!(name: 'Test'))
        @order = create(:order, project: @project)
        @request =
          create(
            :request,
            request_type: create(:request_type),
            project: @project,
            asset: create(:sample_tube),
            target_asset: create(:well)
          )
      end

      context 'without quotas' do
        setup do
          @project.update!(enforce_quotas: false)
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
        setup { @project.update!(enforce_quotas: true) }

        should 'not fail' do
          RequestFactory.copy_request(@request)
        end
      end
    end
  end

  context '.create_assets_requests' do
    setup do
      @study = create(:study)
      @assets = create_list(:sample_tube, 2, study: nil, project: nil)

      RequestFactory.create_assets_requests(@assets, @study)
    end

    should 'have all create asset requests as passed' do
      assert_equal ['passed'], RequestType.find_by(key: 'create_asset').requests.map(&:state).uniq
    end

    should 'have the study on all requests' do
      assert_equal [@study.id], RequestType.find_by(key: 'create_asset').requests.map(&:initial_study_id).uniq
    end

    should 'have the asset IDs' do
      assert_equal @assets.map { |a| a.receptacle.id }.sort,
                   RequestType.find_by(key: 'create_asset').requests.map(&:asset_id).sort
    end
  end
end
