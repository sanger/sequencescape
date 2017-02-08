# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2013,2015,2016 Genome Research Ltd.

require 'test_helper'

class ApiRoutingTest < ActionController::TestCase
  class << self
    def should_not_route(method, path, options)
      matcher = route(method, path).to(options)

      should matcher.description do
        exception_class = defined?(Test::Unit::AssertionFailedError) ? Test::Unit::AssertionFailedError : MiniTest::Assertion
        # Not only can we not be allowed the method, we also might not even have the route!
        assert_raises(ActionController::MethodNotAllowed, exception_class) do
          assert_accepts matcher.in_context(self), self
        end
      end
    end

    def resource_routes(*resources)
      resources_with_nesting = resources.extract_options!

      resources.each do |resource|
        with_options(controller: "api/#{resource}") do |check|
          yield(check, "/0_5/#{resource}", { controller: "api/#{resource}" })

          # We absolutely, never, ever expose :destroy
          check.should_not_route :delete, "/0_5/#{resource}/12345", action: :destroy
        end
      end

      resources_with_nesting.each do |parent, resources|
        resources.each do |resource|
          with_options(:"#{parent.to_s.singularize}_id" => '67890', :controller => "api/#{resource}") do |check|
            yield(check, "/0_5/#{parent}/67890/#{resource}", { :"#{parent.to_s.singularize}_id" => '67890', :controller => "api/#{resource}" })

            # We absolutely, never, ever expose :destroy
            check.should_not_route :delete, "/0_5/#{parent}/67890/#{resource}/12345", action: :destroy
          end
        end
      end
    end

    def read_only_routes(*resources)
      context 'read only resources' do
        resource_routes(*resources) do |context, core_path, controller|
          context.should route(:get, core_path).to(controller.merge(action: :index))
          context.should route(:get, "#{core_path}/12345").to(controller.merge(action: :show, id: '12345'))

          context.should_not_route :post, core_path,            action: :create
          context.should_not_route :put,  "#{core_path}/12345", action: :update, id: '12345'
        end
      end
    end

    def crud_routes(*resources)
      context 'CRUD resources' do
        resource_routes(*resources) do |context, core_path, controller|
          context.should route(:get,  core_path).to(controller.merge(action: :index))
          context.should route(:get,  "#{core_path}/12345").to(controller.merge(action: :show, id: '12345'))
          context.should route(:post, core_path).to(controller.merge(action: :create))
          context.should route(:put,  "#{core_path}/12345").to(controller.merge(action: :update, id: '12345'))
        end
      end
    end
  end

  context 'API routing' do
    read_only_routes(
      :asset_links,
      :batch_requests,
      :batches,
      :events,
      :lanes,
      :library_tubes,
      :multiplexed_library_tubes,
      :plate_purposes,
      :plates,
      :sample_tubes,
      :study_samples,
      :tags,
      :wells,
      :submissions,
      sample_tubes: [:library_tubes, :requests],
      samples: [:sample_tubes],
      library_tubes: [:lanes, :requests]
    )

    crud_routes(
      :requests,
      :samples,
      projects: [:studies],
      studies: [:samples, :projects]
    )

    context 'parent/child relationships' do
      resource_routes(
        :batches,
        :lanes,
        :library_tubes,
        :multiplexed_library_tubes,
        :plates,
        :wells,
        samples: [:sample_tubes]
      ) do |context, core_path, controller|
        context.should route(:get, "#{core_path}/12345/parents").to(controller.merge(action: :parents, id: '12345'))
        context.should route(:get, "#{core_path}/12345/children").to(controller.merge(action: :children, id: '12345'))

        # No other method should be allowed to these resources:
        [:put, :post, :delete].each do |method|
          context.should_not_route method, "#{core_path}/12345/parents",  action: :parents,  id: '12345'
          context.should_not_route method, "#{core_path}/12345/children", action: :children, id: '12345'
        end
      end
    end
  end
end
