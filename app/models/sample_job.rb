# frozen_string_literal: true

# Relates jobs with biomaterials as described by Aker work order
class SampleJob < ApplicationRecord
  belongs_to :sample
  belongs_to :job, class_name: 'Aker::Job', inverse_of: :sample_jobs
end
