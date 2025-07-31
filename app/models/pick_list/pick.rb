# frozen_string_literal: true

# A pick represents an intended cherrypick. It pretty much maps
# exactly to a {CherrypickRequest}. Currently these are just plain old
# Ruby objects, but may end up being database backed in future if we update
# Cherrypicking to avoid the need for submissions. (Although now cherrypicking
# is billed this may be less useful)
class PickList::Pick
  include ActiveModel::Model

  attr_accessor :source_receptacle
  attr_writer :study, :project, :user

  # Used to help group compatible picks together into orders
  def order_options
    { study:, project: }
  end

  def study
    @study || extract_study_from_source_receptacle
  end

  def project
    @project || extract_project_from_source_receptacle
  end

  private

  # Only extract the study from the source source_receptacle if we have just
  # one study. If there are multiple studies, this is a cross-study pool
  # and we don't set study on order.
  def extract_study_from_source_receptacle
    source_receptacle.studies.one? ? source_receptacle.studies.first : nil
  end

  # Only extract the project from the source source_receptacle if we have just
  # one study. If there are multiple projects, this is a cross-project pool
  # and we don't set study on order.
  def extract_project_from_source_receptacle
    source_receptacle.projects.one? ? source_receptacle.projects.first : nil
  end
end
