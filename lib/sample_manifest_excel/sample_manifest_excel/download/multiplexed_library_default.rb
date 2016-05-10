module SampleManifestExcel
  module Download
    class MultiplexedLibraryDefault < Base

        include Tube
        include Multiplexed
        include Default

    end
  end
end