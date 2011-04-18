require "test_helper"

class SampleManifestTest < ActiveSupport::TestCase
  context "A sample manifest (generation)" do
    context "#perform" do
      setup do
        study = Factory :study, :name => 'CARD1'
        study.study_metadata.study_name_abbreviation  = 'CARD1'
        study.save!

        barcode = mock("barcode")
        barcode.stubs(:barcode).returns(23)
        PlateBarcode.stubs(:create).returns(barcode)
        @manifest         = Factory :sample_manifest, :count => 1, :study => study
        @template         = SampleManifestTemplate.first
        printer           = mock("BarcodePrinter")
        @old_sample_count = Sample.count
        @old_plate_count  = Plate.count
        @old_well_count   = Well.count

        plate = mock("plate")
        plate.stubs(:create_barcode_labels_from_plates)
        @manifest.stubs(:stock_plate_purpose).returns(plate)

        @manifest.generate(@template,printer)
      end

      should "change sample plate and well and be an excel file" do
        Delayed::Job.all(:limit => 3).map(&:invoke_job)

        assert_equal (@old_sample_count +  96), Sample.count
        assert_equal (@old_plate_count +1), Plate.count
        assert_equal (@old_well_count + 96), Well.count
        assert_not_nil @manifest.generated.data
        generated_manifest_file = StringIO.new(@manifest.generated.data)
        assert_instance_of Spreadsheet::Excel::Workbook, Spreadsheet.open(generated_manifest_file), "The generated file doesn't look like a spreadsheet."
      end
    end

    context "#check manifest" do
      setup do
        study    = Factory :study, :name => 'CARD1'
        study.study_metadata.study_name_abbreviation  = 'CARD1'
        study.save!
        supplier = Factory :supplier, :name => "Supplier"
        @manifest = Factory :sample_manifest, :study => study, :supplier => supplier, :count => 2
        barcode = mock("barcode")
        barcode.stubs(:barcode).returns(23)
        PlateBarcode.stubs(:create).returns(barcode)
        printer   = mock("BarcodePrinter")
        @old_sample_count = Sample.count
        @old_plate_count = Plate.count
        @old_well_count = Well.count

        plate = mock("plate")
        plate.stubs(:create_barcode_labels_from_plates)
        @manifest.stubs(:stock_plate_purpose).returns(plate)

        @manifest.generate(SampleManifestTemplate.first, printer)

        Tempfile.open('testfile.xls') do |tempfile|
          tempfile.write(@manifest.generated.data)
          tempfile.flush
          tempfile.open

          @spreadsheet = Spreadsheet.open(tempfile.path)
          @worksheet   = @spreadsheet.worksheets.first
        end
      end

      should "change sample plate and well,have 1 worksheet,study name, supplier name, well A1 and vertical order" do
        Delayed::Job.all(:limit => 5).map(&:invoke_job)
        assert_equal (@old_sample_count +  2*96), Sample.count
        assert_equal (@old_plate_count +2), Plate.count
        assert_equal (@old_well_count + 2*96), Well.count
        
        assert_equal 1, @spreadsheet.worksheets.size
        assert_equal 'CARD1', @worksheet[4, 1]
        assert_equal 'Supplier', @worksheet[5, 1]
        assert_equal 'A1', @worksheet[9, 1]
        assert_equal 'B1', @worksheet[10, 1]
      end
    end
  end


  context "A sample manifest (processing)" do
    setup do
      mimetype = "text/csv"
      path     = File.dirname(__FILE__) + '/../data/sample_manifest.csv'
      @manifest = Factory :sample_manifest, :count => 2
      @manifest.uploaded = ActionController::TestUploadedFile.new(path, mimetype)
      @manifest.save
    end

    context "environment" do 
      should "have a CSV uploaded, be parsable" do
        assert_not_nil @manifest.uploaded.data
        assert_not_nil FasterCSV.parse(@manifest.uploaded.data)
      end

      context "contain valid data" do
        setup do
          @csv = FasterCSV.parse(@manifest.uploaded.data)
        end

        should "have a stud name" do
          assert_equal 'ABC_123', @csv[4][1]
        end
      end
    end

    context "#process" do
      setup do

        offset = 290
        234239.upto(234239) do |plate_id|
          plate = Factory :plate, :barcode => plate_id, :size => 96
          1.upto(plate.size) do |i|
            plate.add_and_save_well(Well.new, i%8, i%12)
          end
          plate.wells.each_with_index do |well,index|
            well.sample = Factory :sample, :name => "Sample_#{offset+index}", :sanger_sample_id => "ABC_123#{offset+index}"
          end
        end
        @old_sample_count = Sample.count
        @manifest.process

        Delayed::Job.all(:limit => 1).map(&:invoke_job)
      end

      should "create sample with name, and DNA source of Blood, and not create new samples" do
        assert_equal 'ABC_123302', Sample.find_by_sanger_sample_id("ABC_123302").sample_metadata.supplier_name
        assert_equal 'Sample_302', Sample.find_by_sanger_sample_id("ABC_123302").name
        assert_equal 'Blood', Sample.find_by_sanger_sample_id("ABC_123302").sample_metadata.dna_source
        assert_equal @old_sample_count, Sample.count
      end

    end
  end


  context "An invalid sample manifest (processing)" do
    setup do
      mimetype = "text/csv"
      path     = File.dirname(__FILE__) + '/../data/invalid_sample_manifest.csv'
      @manifest = Factory :sample_manifest, :count => 2
      @manifest.uploaded = ActionController::TestUploadedFile.new(path, mimetype)
    end

    context "#process" do
      setup do
        offset = 290
        234239.upto(234239) do |plate_id|
          plate = Factory :plate, :barcode => plate_id, :size => 96
          1.upto(plate.size) do |i|
            Well.new(:plate=> plate, :map_id => i, :sample => Sample.create!(:name => "Sample_#{offset+i}", :sanger_sample_id => "ABC_123#{offset+i}") )
          end
        end

        @old_sample_count = Sample.count
        @manifest.process

        Delayed::Job.all(:limit => 1).map(&:invoke_job)
      end

      should "not update sample name or dna_source, or create more samples and have errors" do
        assert_not_equal 'ABC_123302', Sample.find_by_sanger_sample_id("ABC_123302").name
        assert_not_equal 'Blood', Sample.find_by_sanger_sample_id("ABC_123302").sample_metadata.dna_source
        assert_equal @old_sample_count, Sample.count
        assert_not_nil SampleManifest.find(@manifest.id).last_errors
      end

    end

  end

end
