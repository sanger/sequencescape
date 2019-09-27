# Controls API V1 IO for {::SubmissionPool}
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
