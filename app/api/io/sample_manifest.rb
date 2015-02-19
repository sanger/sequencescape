#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2011,2012 Genome Research Ltd.
class ::Io::SampleManifest < ::Core::Io::Base
  set_model_for_input(::SampleManifest)
  set_json_root(:sample_manifest)
  set_eager_loading { |model| model.include_samples }

  define_attribute_and_json_mapping(%Q{
    override_previous_manifest <=  override_previous_manifest
                   last_errors  => last_errors
                         state  => state
                      supplier <=  supplier
                         count <=  count

                    io_samples  => samples
                       samples <=  samples
  })
end
