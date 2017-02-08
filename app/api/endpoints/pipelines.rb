# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2015 Genome Research Ltd.

class ::Endpoints::Pipelines < ::Core::Endpoint::Base
  model do
  end

  instance do
    has_many(
      :inbox, scoped: 'ready_in_storage.full_inbox.order_most_recently_created_first',
              include: [],
              json: 'requests', to: 'requests'
    )

    has_many(
      :batches, scoped: 'order_most_recently_updated_first',
                include: [],
                json: 'batches', to: 'batches'
    ) do
      action(:create) do |request, _|
        ActiveRecord::Base.transaction do
          request.create!(::Io::Batch.map_parameters_to_attributes(request.json).merge(user: request.user))
        end
      end
    end
  end
end
