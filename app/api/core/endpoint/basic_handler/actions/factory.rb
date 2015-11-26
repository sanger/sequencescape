#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011,2011,2012 Genome Research Ltd.
module Core::Endpoint::BasicHandler::Actions::Factory
  class Nested < Core::Endpoint::BasicHandler
    def initialize(name, &block)
      super(&block)
      @name = name.to_s
    end

    def separate(associations, _)
      associations[@name] = lambda do |object, options, stream|
        stream.block(@name) do |nested_stream|
          nested_stream.block('actions') do |action_stream|
            actions(object, options.merge(:target => object)).map do |action,url|
              action_stream.attribute(action,url)
            end
          end
        end
      end
    end

    def core_path(*args)
      super(@name, *args)
    end
  end

  def nested(json, &block)
    class_handler = Class.new(Nested).tap { |handler| self.class.const_set(json.to_s.camelize, handler) }
    register_handler(json, class_handler.new(json, &block))
  end
end
