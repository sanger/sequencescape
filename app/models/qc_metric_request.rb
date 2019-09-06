class QcMetricRequest < ApplicationRecord
  belongs_to :qc_metric
  belongs_to :request
  validates :request, :qc_metric, presence: true
end
