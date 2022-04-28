# frozen_string_literal: true

# A work order type is a simple string identifier of the entire work order
# As initial work orders correspond to single request workflow it will initially
# reflect the request type of the provided request.
class WorkOrderType < ApplicationRecord
  validates :name,
            presence: true,
            # Format constraints are intended mainly to keep things consistent, especially with request type keys.
            format: {
              with: /\A[a-z0-9_]+\z/,
              message: 'should only contain lower case letters, numbers and underscores.'
            },
            uniqueness: {
              case_sensitive: false
            }
end
