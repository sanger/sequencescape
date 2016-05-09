module SampleManifestExcel
  class Download

    STANDARD_HEADINGS = [
      "SANGER SAMPLE ID","SUPPLIER SAMPLE NAME","COHORT","VOLUME (ul)",
      "CONC (ng/ul)","GENDER","DNA SOURCE","GC CONTENT","PUBLIC NAME",
      "TAXON ID","COMMON NAME","SAMPLE DESCRIPTION","STRAIN",
      "SAMPLE VISIBILITY","SAMPLE TYPE","PHENOTYPE (required for EGA)"
    ]

    attr_reader :sample_manifest, :worksheet, :columns

    def initialize(sample_manifest)
      @sample_manifest = sample_manifest
      create_columns
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
      worksheet.add_row values
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
      add_row columns.collect(&:heading)
    end

    def create_columns
      columns.tap do |c|
        STANDARD_HEADINGS.each do |heading|
          c << SampleManifestExcel::Column.new(heading: heading)
        end
      end
    end

  end
end