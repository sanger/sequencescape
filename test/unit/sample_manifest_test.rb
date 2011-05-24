require "test_helper"

class SampleManifestTest < ActiveSupport::TestCase
  context "#generate" do
    setup do
      barcode = mock("barcode")
      barcode.stubs(:barcode).returns(23)
      PlateBarcode.stubs(:create).returns(barcode)

      @study = Factory :study, :name => 'CARD1'
      @study.study_metadata.study_name_abbreviation  = 'CARD1'
      @study.save!
    end

    context 'creates the right assets' do
      setup do
        plate = mock("plate")
        plate.stubs(:create_barcode_labels_from_plates)
        PlatePurpose.stubs(:find).returns(plate)
      end

      (1..2).each do |count|
        context "#{count} plate(s)" do
          setup do
            @manifest = Factory :sample_manifest, :study => @study, :count => count
            @manifest.generate
          end

          should_change('Sample.count', :by => (count * 96)) { Sample.count }
          should_change('Plate.count',  :by => (count * 1))  { Plate.count  }
          should_change('Well.count',   :by => (count * 96)) { Well.count   }
        end
      end
    end

    context 'converts to a spreadsheet' do
      setup do
        @manifest = Factory :sample_manifest, :study => @study, :count => 1
        SampleManifestTemplate.first.generate(@manifest)

        @spreadsheet = Spreadsheet.open(StringIO.new(@manifest.generated.data))
        @worksheet   = @spreadsheet.worksheets.first
      end

      should "have 1 worksheet,study name, supplier name, well A1 and vertical order" do
        assert_equal 1, @spreadsheet.worksheets.size
        assert_equal 'CARD1', @worksheet[4, 1]
        assert_equal 'Test supplier', @worksheet[5, 1]
        assert_equal 'A1', @worksheet[9, 1]
        assert_equal 'B1', @worksheet[10, 1]
      end
    end
  end

  def load_manifest_from(filename)
    Factory(:sample_manifest, :count => 2).tap do |manifest|
      manifest.uploaded = 
        ActionController::TestUploadedFile.new(
          File.join(File.dirname(__FILE__), %w{.. data}, filename),
          'text/csv'
        )
      manifest.save!

      manifest.process
      Delayed::Job.all(:limit => 1).map(&:invoke_job)

      manifest.reload
    end
  end

  context "#process" do
    setup do
      offset, plate_id = 290, 234239
      plate = Factory :plate, :barcode => plate_id, :size => 96
      1.upto(plate.size) do |i|
        plate.add_and_save_well(Well.new, i%8, i%12)
      end
      plate.wells.each_with_index do |well,index|
        well.sample = Factory(
          :sample,
          :name             => "Sample_#{offset+index}",
          :sanger_sample_id => "CCC2_VLR#{offset+index}"
        )
      end

      @old_sample_count   = Sample.count
      @sample_ccc2_vlr302 = Sample.find_by_sanger_sample_id('CCC2_VLR302')
    end

    context 'valid CSV file' do
      setup do
        @manifest = load_manifest_from('sample_manifest.csv')
        @sample_ccc2_vlr302.reload
      end

      should "create sample with name, and DNA source of Blood, and not create new samples" do
        assert_equal @old_sample_count, Sample.count
        assert_nil SampleManifest.find(@manifest.id).last_errors

        assert_equal 'CCC2_VLR302', @sample_ccc2_vlr302.sample_metadata.supplier_name
        assert_equal 'Sample_302',  @sample_ccc2_vlr302.name
        assert_equal 'Blood',       @sample_ccc2_vlr302.sample_metadata.dna_source
      end
    end
    
    context 'invalid CSV file' do
      setup do
        @manifest = load_manifest_from('invalid_sample_manifest.csv')
        @sample_ccc2_vlr302.reload
      end

      should "not update sample name or dna_source, or create more samples and have errors" do
        assert_equal @old_sample_count, Sample.count
        assert_not_nil SampleManifest.find(@manifest.id).last_errors

        assert_not_equal 'CCC2_VLR302', @sample_ccc2_vlr302.sample_metadata.supplier_name
        assert_not_equal 'Blood',       @sample_ccc2_vlr302.sample_metadata.dna_source
      end
    end
  end
end
