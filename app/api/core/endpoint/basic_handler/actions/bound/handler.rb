# frozen_string_literal: true
# An instance of this class is responsible for dealing with a particular named action on a
# resource.  It is as though this instance is actually part of the instance that it was
# registered within.
class Core::Endpoint::BasicHandler::Actions::Bound::Handler < Core::Endpoint::BasicHandler
  include Core::Endpoint::BasicHandler::Actions::InnerAction
  include Core::Endpoint::BasicHandler::Paged

  def initialize(owner, name, options, &)
    super(name, options, &)
    @owner = owner
  end

  def owner_for(_request, object)
    endpoint_for_object(object).instance_handler
  rescue => e
    @owner
  end
  private :owner_for

  def core_path(*args)
    args.unshift(@options[:to])
    @owner.send(:core_path, *args)
  end
  private :core_path
end
