# frozen_string_literal: true

# A QC receptacle is generated for a {QcTube}
# Unlike a standard {Receptacle} it does not remove aliquots in response
# to retrospective failures. (That is, when a user forgets to fail a well initially
# and only remembers to do so after child plates have been created) This is because
# while in most cases this indicates a mistake, in the case of QC tubes the failures
# are being made on the basis of information provided by the QC tube.
class Receptacle::Qc < Receptacle
  def process_aliquots(_aliquots_to_remove)
    # Do not remove downstream aliquots
    nil
  end
end
