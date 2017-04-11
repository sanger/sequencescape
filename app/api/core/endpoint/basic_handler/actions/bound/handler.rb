# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2015 Genome Research Ltd.

# An instance of this class is responsible for dealing with a particular named action on a
# resource.  It is as though this instance is actually part of the instance that it was
# registered within.
class Core::Endpoint::BasicHandler::Actions::Bound::Handler < Core::Endpoint::BasicHandler
  include Core::Endpoint::BasicHandler::Actions::InnerAction

  def initialize(owner, name, options, &block)
    super(name, options, &block)
    @owner = owner
  end

  def owner_for(_request, object)
    endpoint_for_object(object).instance_handler
  rescue => exception
    @owner
  end
  private :owner_for

  def core_path(*args)
    args.unshift(@options[:to])
    @owner.send(:core_path, *args)
  end
  private :core_path
end
