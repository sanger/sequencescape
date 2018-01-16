class SampleWorkOrder < ApplicationRecord
  belongs_to :sample
  belongs_to :work_order, class_name: 'Aker::WorkOrder'
end
