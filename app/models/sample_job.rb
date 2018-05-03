class SampleJob < ApplicationRecord
  belongs_to :sample
  belongs_to :job, class_name: 'Aker::Job'
end
