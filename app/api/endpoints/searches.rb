# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2015 Genome Research Ltd.

class ::Endpoints::Searches < ::Core::Endpoint::Base
  module SearchActions
    def search_action(name)
      bind_action(:create, to: name.to_s, as: name.to_sym) do |action, request, response|
        request.json['search']['page'] ||= request.path.fetch(1).to_i if request.path.fetch(1, false)
        scope = request.target.scope(request.json['search']).send(name)
        # If we're not paginated, just convert to an array. This will stop
        # the api from trying to paginate the results. Ideally all searches should be
        # paginated, but this may break downstream clients
        (scope.respond_to?(:total_entries) ? scope : scope.to_a).tap do |results|
          response.handled_by = action
          yield(response, results)
        end
      end
    end

    def singular_search_action(name)
      bind_action(:create, to: name.to_s, as: name.to_sym) do |_action, request, response|
        record = request.target.scope(request.json['search']).send(name.to_sym)
        raise ActiveRecord::RecordNotFound, 'no resources found with that search criteria' if record.nil?

        request.io = ::Core::Io::Registry.instance.lookup_for_object(record)
        request.io.eager_loading_for(record.class).include_uuid.find(record.id).tap do |_result|
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

    search_action(:all) do |response, _records|
      response.multiple_choices
    end
  end
end
