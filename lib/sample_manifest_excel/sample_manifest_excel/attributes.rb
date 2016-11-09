module SampleManifestExcel

  ##
  # Some columns need to extract a value from a sample manifest.
  # This may involve a crazy chain of methods.
  class Attributes

    ##
    # Take the column name and return an attribute class.
    # If the column name relates to a column with an attribute
    # return a new object of that class which when passed a sample
    # will return the correct value.
    # If it isn't an attribute it will return a NullObject
    # which will return a null value when passed a sample.
    def self.find(column_name)
      case column_name.to_sym
      when :sanger_plate_id
        SangerHumanBarcodeAttribute.new
      when :well
        WellAttribute.new
      when :sanger_sample_id, :donor_id, :donor_id_2
        SangerSampleIdAttribute.new
      when :sanger_tube_id
        SangerTubeIdAttribute.new
      else
        NullAttribute.new
      end
    end

    ##
    # Returns a null value
    class NullAttribute
      def value(sample)
      end
    end

    ##
    # Returns sanger human barcode of the plate of the first well
    class SangerHumanBarcodeAttribute
      def value(sample)
        sample.wells.first.plate.sanger_human_barcode
      end
    end

    ##
    # Returns the description of the map of the first well
    class WellAttribute
      def value(sample)
        sample.wells.first.map.description
      end
    end

    ##
    # Return the sanger sample id
    class SangerSampleIdAttribute
      def value(sample)
        sample.sanger_sample_id
      end
    end

    ##
    # Return the sanger human barcode of the first asset.
    class SangerTubeIdAttribute
      def value(sample)
        sample.assets.first.sanger_human_barcode
      end
    end
  end
end
