# frozen_string_literal: true

# This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and authorship of this file.
# Copyright (C) 2018 Genome Research Ltd.

# An automated order is created by an external application, such as Limber.
# Retrieval of studies/projects is surprisingly expensive, and isn't
# relevant for cross-project/study stuff anyway.
# Rather than COMPLETELY disabling validation of study/project presence,
# we use the current permissions for cross study/project-stuff, and auto
# populate the field elsewhere. If someone manages to somehow mix multiple
# assets in different single studies, we still throw validation errors
class AutomatedOrder < FlexibleSubmission
  before_validation :set_study_from_aliqouts, unless: :cross_study_allowed
  before_validation :set_project_from_aliqouts, unless: :cross_project_allowed

  def set_study_from_aliqouts
    studies = assets.reduce(Set.new) { |set, asset| set.merge(asset.studies) }
    self.study = studies.first if studies.one?
  end

  def set_project_from_aliqouts
    projects = assets.reduce(Set.new) { |set, asset| set.merge(asset.projects) }
    self.project = projects.first if projects.one?
  end
end
