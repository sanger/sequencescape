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
      (1..2).each do |count|
        context "#{count} plate(s)" do
          setup do
            @manifest = Factory :sample_manifest, :study => @study, :count => count
            @manifest.generate
          end

          should_change('Sample.count', :by => (count * 96)) { Sample.count }
          should_change('Plate.count',  :by => (count * 1))  { Plate.count  }
          should_change('Well.count',   :by => (count * 96)) { Well.count   }

          should_change("Study.samples.count", :by => (count * 96)) { @study.samples.count }
        end
      end
    end

    context 'converts to a spreadsheet' do
      setup do
        @manifest = Factory :sample_manifest, :study => @study, :count => 1
        @manifest.generate
        SampleManifestTemplate.first.generate(@manifest)

        @spreadsheet = Spreadsheet.open(StringIO.new(@manifest.generated.data))
        @worksheet   = @spreadsheet.worksheets.first
      end

      should "have 1 worksheet,study name, supplier name, well A1 and vertical order" do
        assert_equal 1, @spreadsheet.worksheets.size
        assert_equal 'CARD1', @worksheet[4, 1]
        assert_equal 'Test supplier', @worksheet[5, 1]

        assert_equal 'A1',  @worksheet[  9, 1]
        assert_equal 'B1',  @worksheet[ 10, 1]
        assert_equal 'H12', @worksheet[104, 1]
      end
    end
  end

  context "update event" do
    setup do
      @user = Factory :user
      @well_with_sample_and_plate = Factory :well_with_sample_and_plate
    end
    context "where a well has no plate" do
      setup do
        @well_with_sample_and_without_plate = Factory :well_with_sample_and_without_plate
      end
      should "not try to add an event to a plate" do
        assert_nothing_raised do
          SampleManifest::PlateBehaviour::Core.new(SampleManifest.new).updated_by!(
            @user, [
              @well_with_sample_and_plate.primary_aliquot.sample,
              @well_with_sample_and_without_plate.primary_aliquot.sample
            ]
          )
        end
      end
    end
    context "where a well has a plate" do
      should "add an event to the plate" do
        SampleManifest::PlateBehaviour::Core.new(SampleManifest.new).updated_by!(@user,[@well_with_sample_and_plate.primary_aliquot.sample])
        assert_equal Event.last, @well_with_sample_and_plate.plate.events.last
        assert_not_nil @well_with_sample_and_plate.plate.events.last
      end
    end

  end

  # This is testing a specific case pulled from production where the size of the delayed job 'handler' column was
  # being filled because we're passing large parameter data (it happens that ~37 plates cause this).  Because of this
  # the parameters were being truncated, ironically to create valid YAML, and the production code was erroring
  # because the last parameter was being dropped.  Good thing the plate IDs were last, right!?!!
  context 'creating extremely large manifests' do
    setup do
      # Stub out the behaviour of PlateBarcode so that it can be "fudged"
      PlateBarcode.stubs(:create).returns(Object.new.tap do |fudged_barcode|
        def fudged_barcode.barcode
          @barcode = (@barcode || 0) + 1
        end
      end)

      @manifest = Factory(:sample_manifest, :count => 37, :asset_type => 'plate', :rapid_generation => true)
      @manifest.generate
    end

    should 'have one job per plate' do
      assert_equal(@manifest.count, Delayed::Job.count, 'number of delayed jobs does not match number of plates')
    end

    context 'delayed jobs' do
      setup do
        Delayed::Job.first.invoke_job
      end

      should_change('Well.count',   :by => 96) { Sample.count }
    end
  end
end
