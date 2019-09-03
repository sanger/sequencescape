# frozen_string_literal: true

# A QcTube is a pool made mid-process for Qc purposes, such as via MiSeq sequencing
class QcTube < MultiplexedLibraryTube
  self.receptacle_class = 'Receptacle::Qc'

  delegate :qc_files, :qc_files=, :add_qc_file, to: :parent
end
