class QcTube < MultiplexedLibraryTube
  delegate :qc_files, :qc_files=, :add_qc_file, :to => :parent
end
