class ::Endpoints::Searches < ::Core::Endpoint::Base
  module SearchActions
    def search_action(name, &block)
      instance_eval do
        bind_action(:create, :to => name.to_s, :as => name.to_sym) do |request, response|
          request.target.scope(request.json['search']).send(name.to_sym).tap do |result|
            block.call(response, result)
          end
        end
      end
    end

  end

  model do

  end

  instance do
    extend SearchActions

    search_action(:first) do |response, record|
      raise ActiveRecord::RecordNotFound, 'no resources found with that search criteria' if record.nil?
      response.redirect_to(record.uuid)
    end

    search_action(:last) do |response, record|
      raise ActiveRecord::RecordNotFound, 'no resources found with that search criteria' if record.nil?
      response.redirect_to(record.uuid)
    end

    search_action(:all) do |response, records|
      response.multiple_choices
    end
  end
end
