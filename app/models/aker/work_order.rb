module Aker
  class WorkOrder < ApplicationRecord
    has_many :sample_work_orders, dependent: :destroy
    has_many :samples, through: :sample_work_orders

    validates :aker_id, presence: true

    def as_json(_options = {})
      {
        work_order: {
          id: id,
          aker_id: aker_id
        }
      }
    end
  end
end
