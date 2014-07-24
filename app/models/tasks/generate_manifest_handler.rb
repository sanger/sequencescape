module Tasks::GenerateManifestHandler
  def generate_manifest
    batch = Batch.find(params[:id])
    study = Study.find(params[:study_id])
    csv_string = GenerateManifestsTask.generate_manifests(batch,study)
    send_data csv_string,
      :type => "text/csv",
      :filename=>"#{study.name}_#{batch.id}_manifest.csv",
      :disposition => 'attachment'
  end

  def render_generate_manifest_task(task, params)
    @studies = @batch.studies
  end
end