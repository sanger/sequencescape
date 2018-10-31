class QcTube < MultiplexedLibraryTube
  delegate :qc_files, :qc_files=, :add_qc_file, to: :parent

  def process_aliquots(_aliquots_to_remove)
    # Do not remove downstream aliquots
    nil
  end
end
