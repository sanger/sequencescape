# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2015 Genome Research Ltd.

class GenerateManifestsTask < Task
  def self.generate_manifests(batch, study)
    ManifestGenerator.generate_manifests(batch, study)
  end

  def partial
    'generate_manifests'
  end

  def render_task(workflow, params)
    super
    workflow.render_generate_manifest_task(self, params)
  end

  def do_task(_workflow, _params)
    true
  end
end
