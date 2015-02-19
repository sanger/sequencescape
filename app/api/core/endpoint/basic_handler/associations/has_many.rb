#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011,2011 Genome Research Ltd.
module Core::Endpoint::BasicHandler::Associations::HasMany
  def has_many(name, options, &block)
    class_handler = Class.new(Handler).tap { |handler| self.class.const_set(name.to_s.camelize, handler) }
    register_handler(options[:to], class_handler.new(name, options, &block))
  end
end
