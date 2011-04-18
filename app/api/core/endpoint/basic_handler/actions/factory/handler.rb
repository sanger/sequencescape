# When you've got an object that behaves like a factory the endpoint is able to define that
# a particular path executes that factory.  However, the returned object is then actually
# of (potentially) another class and thus we need the appropriate endpoint for that.
class Core::Endpoint::BasicHandler::Actions::Factory::Handler < Core::Endpoint::BasicHandler
  include Core::Endpoint::BasicHandler::Actions::InnerAction
  include Core::Endpoint::BasicHandler::EndpointLookup

  def initialize(options, &block)
    super(:create, options, &block)
  end

  def owner_for(_, object)
    endpoint_for_object(object).instance_handler
  end
  private :owner_for
end
