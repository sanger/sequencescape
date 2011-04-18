# An instance of this class is responsible for dealing with a particular named action on a
# resource.  It is as though this instance is actually part of the instance that it was
# registered within.
class Core::Endpoint::BasicHandler::Actions::Bound::Handler < Core::Endpoint::BasicHandler
  include Core::Endpoint::BasicHandler::Actions::InnerAction

  def initialize(owner, name, options, &block)
    super(name, options, &block)
    @owner = owner
  end

  def owner_for(request, object)
    endpoint_for(object.class).instance_handler
  rescue => exception
    @owner
  end
  private :owner_for
end
