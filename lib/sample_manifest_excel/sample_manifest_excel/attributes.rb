module SampleManifestExcel
  class Attributes
    
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

    class NullAttribute
      def value(sample)
      end
    end

    class SangerHumanBarcodeAttribute
      def value(sample)
        sample.wells.first.plate.sanger_human_barcode
      end
    end

    class WellAttribute
      def value(sample)
        sample.wells.first.map.description
      end
    end

    class SangerSampleIdAttribute
      def value(sample)
        sample.sanger_sample_id
      end
    end

    class SangerTubeIdAttribute
      def value(sample)
        sample.assets.first.sanger_human_barcode
      end
    end
  end
end