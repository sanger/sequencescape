# frozen_string_literal: true
# A {Task} used in {PacBioSequencingPipeline}
# Assigns tagged tube into multiplexed wells on the target plate for pooling.
#
# @note At time of writing (14/4/2022) this is due for removal.
#
# @see Tasks::AssignTubesToWellsHandler for behaviour included in the {WorkflowsController}
class AssignTubesToMultiplexedWellsTask < Task
end
