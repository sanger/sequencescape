class ExternalProperty < ApplicationRecord
  belongs_to :propertied, polymorphic: true
end
