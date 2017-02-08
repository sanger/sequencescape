# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2015,2016 Genome Research Ltd.

module Tasks::GenerateManifestHandler
  def manifest_filename(name, number)
    [name, number.to_s, 'manifest.csv'].join('_').gsub(/\s/, '_').gsub(/[^A-Za-z0-9_\-\.]/, '')
  end

  def generate_manifest
    batch = Batch.find(params[:id])
    study = Study.find(params[:study_id])
    csv_string = GenerateManifestsTask.generate_manifests(batch, study)
    send_data csv_string,
      type: 'text/csv',
      filename: manifest_filename(study.name, batch.id),
      disposition: 'attachment'
  end

  def render_generate_manifest_task(_task, _params)
    @studies = @batch.studies
  end
end
