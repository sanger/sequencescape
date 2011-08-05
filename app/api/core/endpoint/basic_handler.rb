class Core::Endpoint::BasicHandler
  module Json
    def as_json(options = {})
      request = options[:response].request

      { 'actions' => { } }.tap do |json|
        json['actions'] = Hash[@actions.map do |name, behaviour|
          [ name, core_path(options) ] if accessible_action?(self, behaviour, request, options[:target])
        end.compact]
      end
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
end
