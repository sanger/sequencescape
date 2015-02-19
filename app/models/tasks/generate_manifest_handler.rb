#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011,2012 Genome Research Ltd.
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
