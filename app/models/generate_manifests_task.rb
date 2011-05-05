class GenerateManifestsTask < Task

  def self.generate_manifests(batch,study)
    ManifestGenerator.generate_manifests(batch,study)
  end

  def partial
    "generate_manifests"
  end

  def render_task(workflow, params)
    super
    workflow.render_generate_manifest_task(self, params)
  end

  def do_task(workflow, params)
    true
  end

end
