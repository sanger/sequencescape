# frozen_string_literal: true
# Controls API V1 {::Core::Endpoint::Base endpoints} for Pipelines
class Endpoints::Pipelines < Core::Endpoint::Base
  model {}

  instance do
    has_many(
      :inbox,
      scoped: 'ready_in_storage.full_inbox.order_most_recently_created_first',
      include: [],
      json: 'requests',
      to: 'requests'
    )

    has_many(:batches, scoped: 'order_most_recently_updated_first', include: [], json: 'batches', to: 'batches') do
      action(:create) do |request, _|
        ActiveRecord::Base.transaction do
          request.create!(::Io::Batch.map_parameters_to_attributes(request.json).merge(user: request.user))
        end
      end
    end
  end
end
