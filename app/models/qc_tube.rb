# frozen_string_literal: true

# A QcTube is a pool made mid-process for Qc purposes, such as via MiSeq sequencing
class QcTube < MultiplexedLibraryTube
  self.receptacle_class = 'Receptacle::Qc'

  delegate :qc_files, :qc_files=, :add_qc_file, to: :parent

  # This block is disabled when we have the labware table present as part of the AssetRefactor
  # Ie. This is what will happens now
  AssetRefactor.when_not_refactored do
    # Post refactor this behaviour is on {Receptacle::Qc}
    def process_aliquots(_aliquots_to_remove)
      # Do not remove downstream aliquots
      nil
    end
  end
end
