# frozen_string_literal: true
# A {Task} used in {PacBioSequencingPipeline}
# Assigns a binding kit barcode to the {PacBioLibraryTube}
#
# @note At time of writing (3/4/2019) this is used in:
#   "PacBio Sequencing"
#
# @see Tasks::BindingKitBarcodeHandler for behaviour included in the {WorkflowsController}
class BindingKitBarcodeTask < Task
end
