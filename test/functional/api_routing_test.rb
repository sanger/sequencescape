require "test_helper"

class ApiRoutingTest < ActionController::TestCase
  class << self
    def should_not_route(method, path, options)
      matcher = route(method, path).to(options)

      should matcher.description do
        # Not only can we not be allowed the method, we also might not even have the route!
        assert_raises(ActionController::MethodNotAllowed, Test::Unit::AssertionFailedError) do
          assert_accepts matcher.in_context(self), self
        end
      end
    end

    def resource_routes(*resources, &block)
      resources_with_nesting = resources.extract_options!

      resources.each do |resource|
        with_options(:controller => "api/#{resource}") do |check|
          yield(check, "/0_5/#{resource}")

          # We absolutely, never, ever expose :destroy
          check.should_not_route :delete, "/0_5/#{resource}/12345", :action => :destroy
        end
      end

      resources_with_nesting.each do |parent, resources|
        resources.each do |resource|
          with_options(:"#{parent.to_s.singularize}_id" => '67890', :controller => "api/#{resource}") do |check|
            yield(check, "/0_5/#{parent}/67890/#{resource}")

            # We absolutely, never, ever expose :destroy
            check.should_not_route :delete, "/0_5/#{parent}/67890/#{resource}/12345", :action => :destroy
          end
        end
      end
    end

    def read_only_routes(*resources)
      context 'read only resources' do
        resource_routes(*resources) do |context, core_path|
          context.should_route :get, core_path,            :action => :index
          context.should_route :get, "#{core_path}/12345", :action => :show, :id => '12345'

          context.should_not_route :post, core_path,            :action => :create
          context.should_not_route :put,  "#{core_path}/12345", :action => :update, :id => '12345'
        end
      end
    end

    def crud_routes(*resources)
      context 'CRUD resources' do
        resource_routes(*resources) do |context, core_path|
          context.should_route :get,  core_path,            :action => :index
          context.should_route :get,  "#{core_path}/12345", :action => :show, :id => '12345'
          context.should_route :post, core_path,            :action => :create
          context.should_route :put,  "#{core_path}/12345", :action => :update, :id => '12345'
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
      :quotas,
      :sample_tubes,
      :study_samples,
      :tags,
      :wells,
      :submissions,
      :sample_tubes  => [ :library_tubes, :requests ],
      :samples       => [ :sample_tubes ],
      :library_tubes => [ :lanes, :requests ]
    )

    crud_routes(
      :requests,
      :samples,
      :projects => [ :studies ],
      :studies  => [ :samples, :projects ]
    )

    context 'parent/child relationships' do
      resource_routes(
        :batches,
        :lanes,
        :library_tubes,
        :multiplexed_library_tubes,
        :plates,
        :wells,
        :samples => [ :sample_tubes ]
      ) do |context, core_path|
        context.should_route :get, "#{core_path}/12345/parents",  :action => :parents,  :id => '12345'
        context.should_route :get, "#{core_path}/12345/children", :action => :children, :id => '12345'

        # No other method should be allowed to these resources:
        [ :put, :post, :delete ].each do |method|
          context.should_not_route method, "#{core_path}/12345/parents",  :action => :parents,  :id => '12345'
          context.should_not_route method, "#{core_path}/12345/children", :action => :children, :id => '12345'
        end
      end
    end
  end
end
