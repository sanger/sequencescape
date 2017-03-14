require 'test_helper'
require 'sample_manifest/sample_manifest_generator'

class SampleManifestGeneratorTest < ActiveSupport::TestCase
  attr_reader :generator, :attributes, :study, :supplier, :user, :configuration, :barcode_printer

  def stub_barcode_service
    barcode = mock('barcode')
    barcode.stubs(:barcode).returns(23)
    PlateBarcode.stubs(:create).returns(barcode)
  end

  def setup
    SampleManifestExcel.configure do |config|
      config.folder = File.join('test', 'data', 'sample_manifest_excel')
      config.load!
    end

    @user = create(:user)
    @study = create(:study)
    @supplier = create(:supplier)
    @barcode_printer = create(:barcode_printer)
    @attributes = { "template": 'plate_full', "study_id": study.id, "supplier_id": supplier.id,
                    "count": '4', "asset_type": 'plate' }.with_indifferent_access
    @configuration = SampleManifestExcel.configuration
    stub_barcode_service
  end

  test 'model name should be sample manifest' do
    assert_equal 'SampleManifest', SampleManifestGenerator.model_name
  end

  test 'should not be valid without a user' do
    @generator = SampleManifestGenerator.new(attributes, nil, configuration)
    refute generator.valid?
  end

  test 'should not be valid unless all of the attributes are present' do
    SampleManifestGenerator::REQUIRED_ATTRIBUTES.each do |attribute|
      @generator = SampleManifestGenerator.new(attributes.except(attribute), user, configuration)
      refute generator.valid?
    end
  end

  test 'should not be valid without configuration' do
    @generator = SampleManifestGenerator.new(attributes, user, nil)
    refute generator.valid?
  end

  test 'should not be valid without columns' do
    @generator = SampleManifestGenerator.new(attributes.merge(template: 'dodgy_template'), user, configuration)
    refute generator.valid?
  end

  test 'should create a sample manifest' do
    @generator = SampleManifestGenerator.new(attributes, user, configuration)
    generator.execute
    assert_equal study.id, generator.sample_manifest.study_id
    refute generator.sample_manifest.new_record?
  end

  test 'should raise an error if sample manifest is not valid' do
    assert_raises ActiveRecord::RecordInvalid do
      SampleManifestGenerator.new(attributes.except(:study_id), user, configuration).execute
    end
  end

  test 'should generate sample manifest to create details_array' do
    @generator = SampleManifestGenerator.new(attributes, user, configuration)
    generator.execute
    refute generator.sample_manifest.details_array.empty?
  end

  test 'xlsx file should be generated and saved' do
    @generator = SampleManifestGenerator.new(attributes, user, configuration)
    generator.execute
    assert generator.sample_manifest.generated
  end

  test 'should add a password to the sample manifest' do
    @generator = SampleManifestGenerator.new(attributes, user, configuration)
    generator.execute
    assert generator.sample_manifest.password.present?
  end

  test 'if asset type is not passed sample manifest should still have an asset_type' do
    @generator = SampleManifestGenerator.new(attributes.except(:asset_type).merge(template: 'tube_full'), user, configuration)
    generator.execute
    assert_equal configuration.manifest_types.find_by('tube_full').asset_type, generator.sample_manifest.asset_type
  end

  test 'if asset type is empty sample manifest should still have an asset_type' do
    @generator = SampleManifestGenerator.new(attributes.merge(template: 'tube_full', asset_type: ''), user, configuration)
    generator.execute
    assert_equal configuration.manifest_types.find_by('tube_full').asset_type, generator.sample_manifest.asset_type
  end

  test 'should print labels if barcode printer is present' do
    LabelPrinter::PmbClient.stubs(:get_label_template_by_name).returns('data' => [{ 'id' => 15 }])
    @generator = SampleManifestGenerator.new(attributes.merge(barcode_printer: barcode_printer.name,
                                                              only_first_label: '0'), user, configuration)

    RestClient.expects(:post)
    assert generator.print_job_required?
    generator.execute
    assert generator.print_job_message.has_key?(:notice)
  end

  test 'print job should not be valid with invalid printer name' do
    LabelPrinter::PmbClient.stubs(:get_label_template_by_name).returns('data' => [{ 'id' => 15 }])
    @generator = SampleManifestGenerator.new(attributes.merge(barcode_printer: 'dodgy_printer',
                                                              only_first_label: '0'), user, configuration)
    assert generator.print_job_required?
    generator.execute
    assert generator.print_job_message.has_key?(:error)
  end

  test 'should not have a print job if printer name has not been provided' do
    @generator = SampleManifestGenerator.new(attributes, user, configuration)
    refute generator.print_job_required?
  end

  def teardown
    SampleManifestExcel.reset!
  end
end
