# frozen_string_literal: true

# An automated order is created by an external application, such as Limber.
# Retrieval of studies/projects is surprisingly expensive, and isn't
# relevant for cross-project/study stuff anyway.
# Rather than COMPLETELY disabling validation of study/project presence,
# we use the current permissions for cross study/project-stuff, and auto
# populate the field elsewhere. If someone manages to somehow mix multiple
# assets in different single studies, we still throw validation errors
class AutomatedOrder < FlexibleSubmission
  # When automating submission creation, it is really useful if we can
  # auto-detect studies and projects based on their aliquots. For automated
  # orders this is enabled by default.
  def autodetection_default
    true
  end
end
