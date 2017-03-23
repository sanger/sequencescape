# Enables the bulk creation of the asset links defined by the pairs passed as edges.
require_dependency 'asset_link'
AssetLink::BuilderJob = Struct.new(:links) do
  # For memory resons we need to limit transaction size to 10 links at a time
  TRANSACTION_COUNT = 10
  def perform
    links.each_slice(TRANSACTION_COUNT) do |link_group|
      ActiveRecord::Base.transaction do
        link_group.each do |parent, child|
          # Create edge can accept either a model (which it converts to an endpoint) or
          # an endpoint itself. Using the endpoints directly we avoid the unnecessary
          # database calls, but more importantly avoid the need to instantiate a load of
          # active record objects.
          parent_endpoint = Dag::Standard::EndPoint.new(parent)
          child_endpoint  = Dag::Standard::EndPoint.new(child)
          AssetLink.create_edge(parent_endpoint, child_endpoint)
        end
      end
    end
  end

  def self.create(*args)
    Delayed::Job.enqueue(new(*args))
  end
end
