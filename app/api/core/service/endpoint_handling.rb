# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2011,2015 Genome Research Ltd.

module Core::Service::EndpointHandling
  def self.included(base)
    base.class_eval do
      attr_reader :endpoint
    end
  end

  def instance(action, endpoint)
    @endpoint = endpoint
    @endpoint.instance_handler.send(action, self, path)
  end

  def model(action, endpoint)
    @endpoint = endpoint
    @endpoint.model_handler.send(action, self, path)
  end
end
