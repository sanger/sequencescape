# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2013,2014,2015 Genome Research Ltd.

require 'rexml/text'
# An instance of this class is responsible for the registration of a sample and its sample tube.
# You can think of this as a binding between those two, within the context of a user, study and
# asset group.
#
#--
# NOTE: This is very much a temporary object: after creation the instance will instantly destroy
# itself.  This is primarily done because Rails 2.3 doesn't have the ActiveModel features of
# Rails 3, and we need some of those above-and-beyond just validation.  If required, the after_create
# callback could be removed to keep track of sample registrations.
#++
class SampleRegistrar < ActiveRecord::Base
  # UPGRADE TODO: This hack is horrible! Find out what its doing and fix it!
  def initialize(attributes = {}, what = {})
    super({ sample_attributes: {}, sample_tube_attributes: {} }.merge(attributes.symbolize_keys), what)
  end

  # Raised if the call to SampleRegistrar.register! fails for any reason, and so that calling code
  # can get at the SampleRegistrar instances that were in the process of being created.
  class RegistrationError < StandardError
    attr_reader :sample_registrars

    def initialize(sample_registrars)
      @sample_registrars = sample_registrars
    end
  end

  class AssetGroupHelper
    def initialize
      @asset_groups = {}
    end

    def existing_asset_group?(name)
      return @asset_groups[name] if @asset_groups.key?(name)
      @asset_groups[name] = !AssetGroup.find_by(name: name).nil?
    end
  end

  NoSamplesError = Class.new(RegistrationError)

  # This method is the main registration interface, taking a list of attributes and registering the
  # associated sample and sample tubes.  You get back a list of SampleRegistrar instances.  If anything
  # goes wrong you get a RegistrationError raised.
  def self.register!(registration_attributes)
    # Note that we're explicitly ignoring the ignored records here!

    helper     = AssetGroupHelper.new
    registrars = registration_attributes.map { |attributes| new(attributes.merge(asset_group_helper: helper)) }.reject(&:ignore?)
    raise NoSamplesError, registrars if registrars.empty?
    begin
      # We perform this in a database wide transaction because it is altering several tables.  It also locks
      # the tables from change whilst we validate our instances.
      ActiveRecord::Base.transaction do
        all_valid = registrars.inject(true) { |all_valid_so_far, registrar| registrar.valid? && all_valid_so_far }
        raise RegistrationError, registrars unless all_valid
        registrars.each { |registrar| registrar.save! }
      end

      return registrars
    rescue ActiveRecord::RecordInvalid => exception
      # NOTE: this shouldn't ever happen but you never know!
      raise RegistrationError, registrars
    end
  end

  # We are registering samples on the behalf of a specified user within a specified study
  belongs_to :user
  validates_presence_of :user

  belongs_to :study
  validates_presence_of :study

  belongs_to :sample, validate: true, autosave: true
  accepts_nested_attributes_for :sample
  validates_presence_of :sample

  after_create do |record|
    # NOTE: this looks like it should be 'record.user.is_owner_of(record.sample)' but ActiveRecord and the
    # dynamic methods associated with User and Role causes that not to work.  So you have to be explicit
    # and send the request for the method!
    record.user.send(:is_owner_of, record.sample)
    record.study.samples.concat(record.sample)
    RequestFactory.create_assets_requests([record.sample_tube], record.study)
  end

  # Samples always come in a SampleTube when coming through us
  belongs_to :sample_tube, validate: true, autosave: true
  accepts_nested_attributes_for :sample_tube
  validates_presence_of :sample_tube

  before_validation do |record|
    record.sample_tube.name = record.sample.name
  end
  after_create do |record|
    record.sample_tube.aliquots.create!(sample: record.sample, study: record.study)
  end

  # SampleTubes are registered within an AssetGroup, unless the AssetGroup is unspecified.
  attr_accessor :asset_group_helper
  attr_accessor :asset_group_name
  belongs_to :asset_group, validate: true, autosave: true
  validates_each(:asset_group_name, if: :new_record?) do |record, _attr, value|
    record.errors.add(:asset_group, "#{value} already exists, please enter another name") if record.asset_group_helper.existing_asset_group?(value)
  end

  before_create do |record|
    record.asset_group = SampleRegistrar.create_asset_group_by_name(record.asset_group_name, record.study)
  end

  after_create do |record|
    record.asset_group.assets.concat(record.sample_tube) unless record.asset_group.blank?
  end

  def self.create_asset_group_by_name(name, study)
    return nil if name.blank?
    AssetGroup.find_by(name: name) || AssetGroup.create!(name: name, study: study)
  end

  # This model does not really need to exist but, without Rails 3, we can't easily use the ActiveRecord stuff.
  # So, once have created an instance we immediately destroy it.  Note that, because of the way ActiveRecord
  # works, this *must* be the LAST after_create callback in this file.
  after_create { |record| record.delete }

  # Is this instance to be ignored?
  def ignore?
    !!@ignore
  end
  alias_method :ignore, :ignore?

  def ignore=(ignore)
    @ignore = ('1' == ignore)
  end

  SpreadsheetError = Class.new(StandardError)
  TooManySamplesError = Class.new(SpreadsheetError)

  # Column names from old spreadsheets that need mapping to new names.
  REMAPPED_COLUMN_NAMES = { 'Asset group name' => 'Asset group' }

  # Columns that are required for the spreadsheet to be considered valid.
  REQUIRED_COLUMNS = ['Asset group', 'Sample name']
  REQUIRED_COLUMNS_SENTENCE = REQUIRED_COLUMNS.map { |w| "'#{w}'" }.to_sentence(two_words_connector: ' or ', last_word_connector: ', or ')

  def self.from_spreadsheet(file, study, user)
    workbook = Spreadsheet.open(file.path) or raise SpreadsheetError, 'Problems processing your file. Only Excel spreadsheets accepted'
    worksheet = workbook.worksheet(0)

    # Assume there is always 1 header row
    num_samples = worksheet.count - 1

    if num_samples > configatron.uploaded_spreadsheet.max_number_of_samples
      raise TooManySamplesError, "You can only load #{configatron.uploaded_spreadsheet.max_number_of_samples} samples at a time. Please split the file into smaller groups of samples."
    end

    # Map the header from the spreadsheet (the first row) to the attributes of the sample registrar.  Each column
    # has the same text as the label for the attribute, once it has been HTML unescaped.
    #
    # NOTE: There are two different versions of the spreadsheet in the wild.  One has a 'Volume' column name that
    # needs to be decoded using CGI HTML unescaping (the old format), and the other needs the column decoded
    # using the XML encoding (the new format).  Every column is mapped using both encodings, with the XML version
    # being the preferred decoding.
    definitions = Sample::Metadata.attribute_details.inject({}) do |hash, attribute|
      label   = attribute.to_field_info.display_name
      handler = ->(attributes, value) { attributes[:sample_attributes][:sample_metadata_attributes][attribute.name] = value }
      hash.tap do
        hash[CGI.unescapeHTML(label)]        = handler   # For the old spreadsheets
        hash[REXML::Text.unnormalize(label)] = handler   # For the new spreadsheets
      end
    end.merge(
      'Asset group' => ->(attributes, value) { attributes[:asset_group_name] = value },
      'Sample name' => ->(attributes, value) { attributes[:sample_attributes][:name] = value },
      '2D barcode'  => ->(attributes, value) { attributes[:sample_tube_attributes][:two_dimensional_barcode] = value },
      'Reference Genome' => ->(attributes, value) { attributes[:sample_attributes][:sample_metadata_attributes][:reference_genome_id] = ReferenceGenome.find_by(name: value).try(:id) || 0 }
    )

    # Map the headers to their attribute handlers.  Ensure that the required headers are present.
    used_definitions, headers = [], []
    column_index, column_name = 0, worksheet.cell(0, 0).to_s.gsub(/\000/, '').gsub(/\.0/, '').strip
    until column_name.empty?
      column_name = REMAPPED_COLUMN_NAMES.fetch(column_name, column_name)
      handler     = definitions[column_name]
      unless handler.nil?
        used_definitions[column_index] = handler
        headers << column_name
      end

      column_index = column_index + 1
      column_name  = worksheet.cell(0, column_index).to_s.gsub(/\000/, '').gsub(/\.0/, '').strip
    end

    if (headers & REQUIRED_COLUMNS) != REQUIRED_COLUMNS
      raise SpreadsheetError, "Please check that your spreadsheet is in the latest format: one of #{REQUIRED_COLUMNS_SENTENCE} is missing or in the wrong column."
    end

    # Build a SampleRegistrar instance for each row of the spreadsheet, mapping the cells of the
    # spreadsheet to their appropriate attribute.
    sample_registrars = []
    1.upto(num_samples) do |row|
      attributes = {
        asset_group_helper: SampleRegistrar::AssetGroupHelper.new,
        sample_attributes: {
          sample_metadata_attributes: {}
        },
        sample_tube_attributes: {}
      }

      used_definitions.each_with_index do |handler, index|
        next if handler.nil?
        value = worksheet.cell(row, index).to_s.gsub(/\000/, '').gsub(/\.0/, '').strip
        handler.call(attributes, value) unless value.blank?
      end
      next if attributes[:sample_attributes][:name].blank?

      # Store the sample registration and check that it is valid.  This will mean that the
      # UI will display any errors without the user having to submit the form to find out.

      SampleRegistrar.new(attributes.merge(study: study, user: user)).tap do |sample_registrar|
        sample_registrars.push(sample_registrar)
        sample_registrar.valid?
      end
    end

    return sample_registrars
  rescue Ole::Storage::FormatError => exception
    raise SpreadsheetError, 'Problems processing your file. Only Excel spreadsheets accepted'
  end
end
