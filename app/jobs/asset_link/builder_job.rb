# frozen_string_literal: true

# An AssetLink::BuilderJob receives an array of [parent_id, child_id] and builds asset links between them
# @return []
AssetLink::BuilderJob =
  Struct.new(:links) do
    def perform # rubocop:todo Metrics/MethodLength
      # For memory reasons we need to limit transaction size to 10 links at a time
      transaction_count = 10

      links
        .uniq
        .each_slice(transaction_count) do |link_group|
          ActiveRecord::Base.transaction do
            link_group.each do |parent, child|
              # Create edge can accept either a model (which it converts to an endpoint) or
              # an endpoint itself. Using the endpoints directly we avoid the unnecessary
              # database calls, but more importantly avoid the need to instantiate a load of
              # active record objects.
              parent_endpoint = Dag::Standard::EndPoint.new(parent)
              child_endpoint = Dag::Standard::EndPoint.new(child)
              AssetLink.create_edge(parent_endpoint, child_endpoint)
            end
          end
        end
    end

    def self.create(*)
      Delayed::Job.enqueue(new(*))
    end
  end
