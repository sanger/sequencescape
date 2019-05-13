# frozen_string_literal: true

# ProductLine represents the team doing the work. Used primarily to group together
# {SubmissionTemplate submission templates} for display, but is also used in downstream
# reporting.
#
# @note This value is becoming increasingly unreliable as the teams become more adaptable
#       with sharing workload. It is probably not a good idea to base critical behaviour off this.
class ProductLine < ApplicationRecord
  has_many :request_types
  has_many :submission_templates
end
