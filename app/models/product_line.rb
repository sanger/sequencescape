
class ProductLine < ApplicationRecord
  has_many :request_types
  has_many :submission_templates
end
