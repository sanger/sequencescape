class PolyMetadatum < ApplicationRecord
  belongs_to :metadatable, polymorphic: true
end
