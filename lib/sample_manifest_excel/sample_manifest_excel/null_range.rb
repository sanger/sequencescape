module SampleManifestExcel

  class NullRange

    def reference
      "A1:A10"
    end

    def absolute_reference
      "worksheet1!#{reference}"
    end

  end

end