#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2011 Genome Research Ltd.
module Core::Service::EndpointHandling
  def self.included(base)
    base.class_eval do
      attr_reader :endpoint
    end
  end

  def instance(action, endpoint)
    benchmark('Instance handling') do
      @endpoint = endpoint
      @endpoint.instance_handler.send(action, self, path)
    end
  end

  def model(action, endpoint)
    benchmark('Model handling') do
      @endpoint = endpoint
      @endpoint.model_handler.send(action, self, path)
    end
  end
end
