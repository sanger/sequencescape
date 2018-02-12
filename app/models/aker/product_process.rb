module Aker
  class ProductProcess < ApplicationRecord
    belongs_to :product, class_name: 'Product', foreign_key: :aker_product_id, required: true
    belongs_to :process, class_name: 'Process', foreign_key: :aker_process_id, required: true

    validates :stage, presence: true
  end
end
