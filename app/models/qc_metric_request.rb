class QcMetricRequest < ApplicationRecord
  belongs_to :qc_metric
  belongs_to :request
  validates_presence_of :request, :qc_metric
end
