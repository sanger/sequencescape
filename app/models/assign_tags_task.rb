# frozen_string_literal: true
# A {Task} used in {LibraryCreationPipeline library creation pipelines}
# Applies the selected tags to the {LibraryTube library tubes}.
# Also appears to create and pool into a {MultiplexedLibraryTube}
#
# @note At time of writing (3/4/2019) this is used in:
#   "PacBio Tagged Library Prep" (As a subclass)
#
# @see Tasks::AssignTagsHandler for behaviour included in the {WorkflowsController}
class AssignTagsTask < Task
end
