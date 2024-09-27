# frozen_string_literal: true
class Core::Endpoint::BasicHandler::Associations::HasMany::Handler < Core::Endpoint::BasicHandler
  include Core::Endpoint::BasicHandler::Paged

  def initialize(association, options, &)
    super(&)
    @association, @options = association, options
  end

  %i[create update delete].each do |action|
    line = __LINE__ + 1
    class_eval(
      "
      def #{action}(request, path)
        nested_action(request, path, request.target.send(@association)) do
          super
        end
      end
    ",
      __FILE__,
      line
    )
  end

  def results_per_page
    @options[:per_page] || super
  end

  def association_details_for(request)
    association_class = request.target.class.reflections[@association.to_s].klass
    association_io = ::Core::Io::Registry.instance.lookup_for_class(association_class)
    yield(association_io)
  end
  private :association_details_for

  def association_from(request)
    association = request.target.send(@association)
    association = @options[:scoped].split('.').inject(association) { |c, m| c.send(m) } if @options.key?(:scoped)
    association
  end
  private :association_from

  def nested_action(request, _path, association)
    uuid = request.target.uuid
    association_details_for(request) do |association_io|
      request.io = association_io
      request.push(association) do
        association.singleton_class.send(:define_method, :uuid) { uuid } unless association.respond_to?(:uuid)
        yield
      end
    end
  end
  private :nested_action

  def read(request, path)
    association_details_for(request) do |association_io|
      association = association_from(request)
      eager_loaded = association_io.eager_loading_for(association).include_uuid
      nested_action(request, path, page_of_results(eager_loaded, path.first.try(:to_i) || 1, association)) { super }
    end
  end

  def _read(request, _)
    yield(self, request.target)
  end
  private :_read
  standard_action(:read)

  def separate(associations, _) # rubocop:todo Metrics/AbcSize, Metrics/MethodLength
    associations[@options[:json].to_s] = lambda do |object, options, stream|
      stream.block(@options[:json].to_s) do |nested_stream|
        association = object.send(@association)
        nested_stream.attribute('size', association.count)

        nested_stream.block('actions') do |action_stream|
          actions(count_of_pages(association), options.merge(target: object)).map do |action, url|
            action_stream.attribute(action, url)
          end
        end
      end
    end
  end

  def core_path(*args)
    options = args.extract_options!
    options[:response].request.service.api_path(options[:target].uuid, @options[:to], *args)
  end
  private :core_path
end
