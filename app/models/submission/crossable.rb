# frozen_string_literal: true
module Submission::Crossable
  def cross_study_allowed
    assets.any? { |a| a.studies.distinct.many? }
  end

  def cross_project_allowed
    assets.any? { |a| a.projects.distinct.many? }
  end

  def cross_compatible?
    true
  end
end
