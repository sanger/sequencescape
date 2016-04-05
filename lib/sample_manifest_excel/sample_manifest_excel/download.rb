module SampleManifestExcel
  class Download

    attr_reader :sample_manifest, :worksheet, :columns, :type

    def initialize(sample_manifest, column_list)
      @sample_manifest = sample_manifest
      @type = sample_manifest.asset_type
      @columns = column_list
      add_attributes
      create_worksheet
    end

    def save(filename)
      xls.serialize(filename)
    end

    def xls
      @xls ||= Axlsx::Package.new
    end

    def workbook
      xls.workbook
    end

    def add_worksheet(name)
      @worksheet = workbook.add_worksheet(name: name)
    end

    def add_row(values = [])
      worksheet.add_row values, types: [:string]*values.length
    end

    def add_rows(n)
      n.times { |i| add_row }
    end

    def columns
      @columns ||= []
    end

  private

    def create_worksheet
      add_worksheet("DNA Collections Form")
      add_row ["DNA Collections Form"]
      add_rows(3)
      add_row ["Study:", sample_manifest.study.abbreviation]
      add_row ["Supplier:", sample_manifest.supplier.name]
      add_rows(2)
      add_row columns.headings
      sample_manifest.samples.each do |sample|
        add_row([sample.wells.first.plate.sanger_human_barcode, sample.wells.first.map.description, sample.sanger_sample_id] + [""]*14 + [sample.sanger_sample_id])
      end
    end

    def add_attributes
      columns.find_by("sanger_plate_id").attribute = Proc.new { |sample| sample.wells.first.plate.sanger_human_barcode }
      columns.find_by("well").attribute = Proc.new { |sample| sample.wells.first.map.description }
      columns.find_by("donor_id").attribute = Proc.new { |sample| sample.sanger_sample_id }
    end

  end
end