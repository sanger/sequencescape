# frozen_string_literal: true
#--
# This is a complete hack of the standard behaviour and quite rightly so: people shouldn't be using it and
# so it is going to go.  Rather than pollute the main API code with this rubbish it's here.
#++
# Controls API V1 {::Core::Endpoint::Base endpoints} for Uuids
class Endpoints::Uuids < Core::Endpoint::Base
  module Response
    def redirect_to(path)
      @owner.request.service.status(301)
      @owner.request.service.headers('Location' => path)
      render_body_json_directly
    end

    def multiple_choices
      @owner.request.service.status(300)
      render_body_json_directly
    end

    def render_body_json_directly
      def @owner.each
        yield(object.to_json)
      end
    end
    private :render_body_json_directly
  end

  class Search
    class CriteriaInvalid < ::Core::Service::Error
      def initialize(*args)
        super
        @errors = { lookup: [message] }
      end

      def api_error(response)
        response.content_error(422, @errors)
      end
    end

    include ::Validateable

    attr_reader :lookup
    protected :lookup
    validates_presence_of :lookup, message: 'should be a tuple'
    validates_each(:lookup, allow_blank: true) do |record, field, value|
      record.errors.add(field, 'should be a tuple') unless value.is_a?(Hash)
    end

    def self.attribute_delegate(*names) # rubocop:todo Metrics/MethodLength
      names.each do |name|
        line = __LINE__ + 1
        class_eval(
          "
          def #{name}
            return nil unless lookup.respond_to?(:fetch)
            lookup[#{name.to_s.inspect}]
          end
          protected #{name.to_sym.inspect}
        ",
          __FILE__,
          line
        )
      end
    end

    attribute_delegate(:id, :model)
    validates_numericality_of :id, only_integer: true, greater_than: 0, allow_blank?: false
    validates_presence_of :model

    def initialize(attributes)
      @lookup = attributes
    end

    def self.create!(attributes)
      search = new(attributes)
      search.validate! {}
      search
    end

    def self.create_bulk!(list_of_attributes)
      raise CriteriaInvalid, 'should be an array of tuples' if list_of_attributes.nil?
      raise CriteriaInvalid, 'should be an array of tuples' unless list_of_attributes.is_a?(Array)
      raise CriteriaInvalid, "can't be blank" if list_of_attributes.blank?
      raise CriteriaInvalid, 'should be a tuple' unless list_of_attributes.all?(Hash)

      list_of_attributes.map(&method(:create!))
    end

    def find
      Uuid.find_uuid_instance!(model.classify, id)
    end
  end

  model do
    # You should not be able to read UUIDs
    disable(:read)

    # Does an individual resource lookup
    bind_action(:create, to: 'lookup', as: :lookup) do |_, request, response|
      lookup = request.json.respond_to?(:keys) ? request.json['lookup'] : nil
      uuid = Search.create!(lookup).find

      # Hack time ...
      class << response
        include ::Endpoints::Uuids::Response
      end
      response.redirect_to(request.service.api_path(uuid.external_id))

      {
        'model' => uuid.resource_type.underscore,
        'id' => uuid.resource_id,
        'uuid' => uuid.external_id,
        'url' => request.service.api_path(uuid.external_id)
      }
    end
    bound_action_not_require_an_io_class?(:lookup)

    # Handles trying to find multiple resources
    bind_action(:create, to: 'bulk', as: :bulk) do |_, request, response|
      lookup = request.json.respond_to?(:keys) ? request.json['lookup'] : nil
      uuids = Search.create_bulk!(lookup).map(&:find)

      # Hack time ...
      class << response
        include ::Endpoints::Uuids::Response
      end
      response.multiple_choices

      uuids.map do |uuid|
        {
          'model' => uuid.resource_type.underscore,
          'id' => uuid.resource_id,
          'uuid' => uuid.external_id,
          'url' => request.service.api_path(uuid.external_id)
        }
      end
    end
    bound_action_not_require_an_io_class?(:bulk)
  end
end
