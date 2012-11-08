class ::Endpoints::Searches < ::Core::Endpoint::Base
  module SearchActions
    def search_action(name, &block)
      bind_action(:create, :to => name.to_s, :as => name.to_sym) do |action, request, response|
        request.target.scope(request.json['search']).send(name).tap do |results|
          response.handled_by = action
          block.call(response, results)
        end
      end
    end

    def singular_search_action(name)
      bind_action(:create, :to => name.to_s, :as => name.to_sym) do |action, request, response|
        record = request.target.scope(request.json['search']).send(name.to_sym)
        raise ActiveRecord::RecordNotFound, 'no resources found with that search criteria' if record.nil?

        request.io = ::Core::Io::Registry.instance.lookup_for_object(record)
        request.io.eager_loading_for(record.class).include_uuid.find(record.id).tap do |result|
          response.redirect_to(record.uuid)
        end
      end
    end
  end

  model do

  end

  instance do
    extend SearchActions

    singular_search_action(:first)
    singular_search_action(:last)

    search_action(:all) do |response, records|
      response.multiple_choices
    end
  end
end
