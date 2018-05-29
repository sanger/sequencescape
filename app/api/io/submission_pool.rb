# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2015 Genome Research Ltd.

class ::Io::SubmissionPool < ::Core::Io::Base
  set_model_for_input(::SubmissionPool)
  set_json_root(:submission_pool)
  set_eager_loading { |model| model }

  define_attribute_and_json_mapping("
    plates_in_submission => plates_in_submission
    used_tag_layout_templates => used_tag_layout_templates
    used_tag2_layout_templates => used_tag2_layout_templates
  ")
end
