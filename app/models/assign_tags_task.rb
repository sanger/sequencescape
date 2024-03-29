# frozen_string_literal: true
# A {Task} used in {LibraryCreationPipeline library creation pipelines}
# Applies the selected tags to the {LibraryTube library tubes}.
# Also appears to create and pool into a {MultiplexedLibraryTube}
#
# @note At time of writing (14/4/2022) this is unused and can be removed once the
# corresponding migrations have been run
#
# @see Tasks::AssignTagsHandler for behaviour included in the {WorkflowsController}
class AssignTagsTask < Task
end
