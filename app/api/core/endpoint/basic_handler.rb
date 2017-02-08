# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2013,2015 Genome Research Ltd.

class Core::Endpoint::BasicHandler
  module Json
    def actions(object, options)
      Hash[@actions.select do |_name, behaviour|
        accessible_action?(self, behaviour, options[:response].request, object)
      end.map do |name, _behaviour|
        [name, core_path(options)]
      end]
    end
    private :actions

    def root_json
      'unknown'
    end

    def related
      []
    end

    def tree_for(_object, _options)
      associations, actions = {}, {}
      related.each { |r| r.separate(associations, actions) }
      Core::Io::Json::Grammar::Root.new(
        root_json,
        associations.merge('actions' => Core::Io::Json::Grammar::Actions.new(self, actions))
      )
    end

    def core_path(*args)
      options  = args.extract_options!
      response = options[:response]

      root =
        if options[:target].respond_to?(:uuid)
          options[:target].uuid
        elsif not options[:endpoint].nil?
          options[:endpoint].root
        elsif not response.request.endpoint.nil?
          response.request.endpoint.root
        end
      args.unshift(root) unless root.nil?

      options[:response].request.service.api_path(*args)
    end
    private :core_path

    def attach_action(name, behaviour = name)
      @actions[name.to_sym] = behaviour.to_sym
    end
    private :attach_action
  end

  extend Core::Endpoint::BasicHandler::Actions::Standard

  def initialize(&block)
    @actions = self.class.standard_actions.dup
    super
    instance_eval(&block) if block_given?
  end

  include Core::Endpoint::BasicHandler::Json
  include Core::Endpoint::BasicHandler::Actions
  include Core::Endpoint::BasicHandler::Handlers
  include Core::Endpoint::BasicHandler::Associations::HasMany
  include Core::Endpoint::BasicHandler::Associations::BelongsTo
  include Core::Endpoint::BasicHandler::Associations::HasFile
end
