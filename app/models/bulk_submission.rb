# Encoding: utf-8

# Previously this was extending Array globally.
# https://ruby-doc.org/core-2.4.2/doc/syntax/refinements_rdoc.html
module ArrayWithFieldList
  refine Array do
    def comma_separate_field_list_for_display(*fields)
      field_list(*fields).join(', ')
    end

    def field_list(*fields)
      map { |row| fields.map { |field| row[field] } }.flatten.delete_if(&:blank?)
    end
  end
end

# A bulk submission is created through the upload of a spreadsheet (csv)
# It contains the information for setting up one or more {Submission submissions},
# allowing for the quick request of multiple pieces of work simultaneously.
# Bulk Submissions are not currently persisted.
class BulkSubmission
  # Activates the ArrayWithFieldList refinements for this class
  using ArrayWithFieldList
  # This is the default output from excel
  DEFAULT_ENCODING = 'Windows-1252'.freeze

  include ActiveModel::AttributeMethods
  include ActiveModel::Validations
  include ActiveModel::Conversion
  extend ActiveModel::Naming

  include Submission::AssetSubmissionFinder

  attr_accessor :spreadsheet, :encoding

  define_attribute_methods [:spreadsheet]

  validates :spreadsheet, presence: true
  validate :process_file

  def persisted?; false; end

  def id; nil; end

  def initialize(attrs = {})
    self.spreadsheet = attrs[:spreadsheet]
    self.encoding = attrs.fetch(:encoding, DEFAULT_ENCODING)
  end

  include ManifestUtil

  def process_file
    # Slightly inelegant file-type checking
    # TODO (jr) Find a better way of verifying the CSV file?
    if spreadsheet.present?
      if spreadsheet.size == 0
        errors.add(:spreadsheet, 'The supplied file was empty')
      else
        if spreadsheet.original_filename.end_with?('.csv')
          process
        else
          errors.add(:spreadsheet, 'The supplied file was not a CSV file')
        end
      end
    end
  rescue CSV::MalformedCSVError
    errors.add(:spreadsheet, 'The supplied file was not a valid CSV file (try opening it with MS Excel)')
  rescue Encoding::InvalidByteSequenceError
    errors.add(:encoding, "didn't match for the provided file.")
  end

  def headers
    @headers ||= filter_end_of_header(@csv_rows.fetch(header_index)) unless header_index.nil?
  end
  private :headers

  def csv_data_rows
    @csv_rows.slice(header_index + 1...@csv_rows.length)
  end
  private :csv_data_rows

  def header_index
    @header_index ||= @csv_rows.each_with_index do |row, index|
      next if index == 0 && row[0] == 'This row is guidance only'
      return index if header_row?(row)
    end
    # We've got through all rows without finding a header
    errors.add(:spreadsheet, 'The supplied file does not contain a valid header row (try downloading a template)')
    nil
  end
  private :header_index

  def start_row
    header_index + 2
  end
  private :start_row

  def header_row?(row)
    row.each { |col| col.try(:downcase!) }
    (row & COMMON_FIELDS).length > 0
  end
  private :header_row?

  def valid_header?
    return false if headers.nil?
    return true if headers.include? 'submission name'

    errors.add :spreadsheet, "You submitted an incompatible spreadsheet. Please ensure your spreadsheet contains the 'submission name' column"
    false
  end

  def max_priority(orders)
    orders.inject(0) do |max, order|
      priority = Submission::Priorities.priorities.index(order['priority']) || order['priority'].to_i
      priority > max ? priority.to_i : max
    end
  end
  private :max_priority

  def spreadsheet_valid?
    valid_header?
    errors.count == 0
  end
  private :spreadsheet_valid?

  def process
    # Store the details of the successful submissions so the user can be presented with a summary
    @submission_ids = []
    @completed_submissions = {}

    csv_content = spreadsheet.read
    @csv_rows = CSV.parse(csv_content.encode!('utf-8', encoding))

    if spreadsheet_valid?
      submission_details = submission_structure

      raise ActiveRecord::RecordInvalid, self if errors.count > 0

      # Within a single transaction process each of the rows of the CSV file as a separate submission.  Any name
      # fields need to be mapped to IDs, and the 'assets' field needs to be split up and processed if present.
      ActiveRecord::Base.transaction do
        submission_details.each do |submissions|
          submissions.each do |submission_name, orders|
            user = User.find_by(login: orders.first['user login'])
            if user.nil?
              errors.add :spreadsheet, orders.first['user login'].nil? ? "No user specified for #{submission_name}" : "Cannot find user #{orders.first["user login"].inspect}"
              next
            end

            begin
              orders_processed = orders.map(&method(:prepare_order)).compact

              submission = Submission.create!(name: submission_name, user: user, orders: orders_processed,
                                              priority: max_priority(orders))
              submission.built!
              # Collect successful submissions
              @submission_ids << submission.id
              @completed_submissions[submission.id] = "Submission #{submission.id} built (#{submission.orders.count} orders)"
            rescue Submission::ProjectValidation::Error => e
              errors.add :spreadsheet, "There was an issue with a project: #{e.message}"
            end
          end
        end

        # If there are any errors then the transaction needs to be rolled back.
        raise ActiveRecord::Rollback if errors.present?
      end

    end
  end

  COMMON_FIELDS = [
    # Needed to construct the submission ...
    'template name',
    'study id', 'study name',
    'project id', 'project name', 'submission name',
    'user login',

    # Needed to identify the assets and what happens to them ...
    'asset group id', 'asset group name',
    'fragment size from', 'fragment size to',
    'pcr cycles',
    'primer panel',
    'read length',
    'library type',
    'bait library', 'bait library name',
    'comments',
    'number of lanes',
    'pre-capture plex level',
    'pre-capture group',
    'gigabases expected',
    'priority'
  ].freeze

  ALIAS_FIELDS = {
    'plate barcode' => 'barcode',
    'tube barcode' => 'barcode'
  }.freeze

  def translate(header)
    ALIAS_FIELDS[header] || header
  end

  def validate_entry(header, pos, row, index)
    return [translate(header), row[pos].try(:strip)] unless header.nil? && row[pos].present?

    errors.add(:spreadsheet, "Row #{index}, column #{pos + 1} contains data but no heading.")
    nil
  end
  private :validate_entry

  # Process CSV into a structure
  #  this creates an array containing a hash for each distinct "submission name"
  #    "submission name" => array of orders
  #    where each order is a hash of headers to values (grouped by "asset group name")
  def submission_structure
    Hash.new { |h, i| h[i] = Array.new }.tap do |submission|
      csv_data_rows.each_with_index do |row, index|
        next if row.all?(&:nil?)

        details = headers.each_with_index.filter_map do |header, pos|
          validate_entry(header, pos, row, index + start_row)
        end.to_h.merge('row' => index + start_row)
        submission[details['submission name']] << details
      end
    end.map do |submission_name, rows|
      order = rows.group_by do |details|
        details['asset group name']
      end.map do |_group_name, rows|
        shared_options!(rows).to_h.tap do |details|
          details['rows']          = rows.comma_separate_field_list_for_display('row')
          details['asset ids']     = rows.field_list('asset id', 'asset ids')
          details['asset names']   = rows.field_list('asset name', 'asset names')
          details['plate well']    = rows.field_list('plate well')
          details['barcode']       = rows.field_list('barcode')
        end.delete_if { |_, v| v.blank? }
      end
      { submission_name => order }
    end
  end

  def shared_options!(rows)
    # Builds an array of the common fields. Raises and exception if the fields are inconsistent
    COMMON_FIELDS.map do |field|
      option = rows.map { |r| r[field] }.uniq
      if option.count > 1
        provided_values = option.map { |o| "'#{o}'" }.to_sentence
        errors.add(:spreadsheet,
                   "#{field} should be identical for all requests in asset group '#{rows.first['asset group name']}'. Given values were: #{provided_values}.")
      end
      [field, option.first]
    end
  end

  def add_study_to_assets(assets, study)
    assets.map(&:samples).flatten.uniq.each do |sample|
      sample.studies << study unless sample.studies.include?(study)
    end
  end

  def extract_request_options(details)
    {
      read_length: details['read length'],
      multiplier: {}
    }.tap do |request_options|
      request_options['library_type'] = details['library type'] if details['library type'].present?
      if details['fragment size from'].present?
        request_options['fragment_size_required_from']   = details['fragment size from']
      end
      if details['fragment size to'].present?
        request_options['fragment_size_required_to']     = details['fragment size to']
      end
      request_options['pcr_cycles'] = details['pcr cycles'] if details['pcr cycles'].present?
      if details['bait library name'].present?
        request_options[:bait_library_name]              = details['bait library name']
      end
      request_options[:bait_library_name] ||= details['bait library'] if details['bait library'].present?
      if details['pre-capture plex level'].present?
        request_options['pre_capture_plex_level']        = details['pre-capture plex level']
      end
      if details['gigabases expected'].present?
        request_options['gigabases_expected']            = details['gigabases expected']
      end
      request_options['primer_panel_name'] = details['primer panel'] if details['primer panel'].present?
    end
  end

  # Returns an order for the given details
  def prepare_order(details) # rubocop:todo Metrics/CyclomaticComplexity
    # Retrieve common attributes
    study   = Study.find_by_id_or_name!(details['study id'], details['study name'])
    project = Project.find_by_id_or_name!(details['project id'], details['project name'])
    user    = User.find_by(login: details['user login']) or raise StandardError, "Cannot find user #{details['user login'].inspect}"

    # Extract the request options from the row details
    request_options = extract_request_options(details)

    # Check the library type matches a value from the table
    if request_options['library_type'].present?
      # find is case insensitive but we want the correct case sensitive name for requests or we get issues downstream in NPG
      lt = LibraryType.find_by(name: request_options['library_type'])&.name or
        raise StandardError, "Cannot find library type #{request_options['library_type'].inspect}"
      request_options['library_type'] = lt
    end

    # Set up the order attributes
    attributes = {
      study: study,
      project: project,
      user: user,
      comments: details['comments'],
      request_options: request_options,
      pre_cap_group: details['pre-capture group']
    }

    # Deal with the asset group: either it's one we should be loading, or one we should be creating.

    attributes[:asset_group] = study.asset_groups.find_by_id_or_name(details['asset group id'],
                                                                     details['asset group name'])
    attributes[:asset_group_name] = details['asset group name'] if attributes[:asset_group].nil?

    ##
    # We go ahead and find our assets regardless of whether we have an asset group.
    # While this takes longer, it helps to detect cases where an asset group name has been
    # reused. This is a common cause of submission problems.

    # Locate either the assets by name or ID, or find the plate and it's well
    if is_plate?(details)

      found_assets = find_wells_including_samples_for!(details)
    # We've probably got a tube
    elsif is_tube?(details)

      found_assets = find_tubes_including_samples_for!(details)

    else

      asset_ids, asset_names = details.fetch('asset ids', ''), details.fetch('asset names', '')
      found_assets = if attributes[:asset_group] && asset_ids.blank? && asset_names.blank?
                       []
                     elsif asset_names.present?
                       Array(find_all_assets_by_name_including_samples!(asset_names)).uniq
                     elsif asset_ids.present?
                       raise StandardError, 'Specifying assets by id is no longer possible. Please provide a name or barcode.'
                     else
                       raise StandardError, 'Please specify a barcode or name for each asset.'
                     end

      assets_found, expecting = found_assets.map do |asset|
                                  "#{asset.name}(#{asset.id})"
                                end, asset_ids.size + asset_names.size
      if assets_found.size < expecting
        raise StandardError, "Too few assets found for #{details['rows']}: #{assets_found.inspect}"
      end
      if assets_found.size > expecting
        raise StandardError, "Too many assets found for #{details['rows']}: #{assets_found.inspect}"
      end

    end

    if attributes[:asset_group].nil?
      attributes[:assets] = found_assets
    elsif found_assets.present? && found_assets != attributes[:asset_group].assets
      raise StandardError, "Asset Group '#{attributes[:asset_group].name}' contains different assets to those you specified. You may be reusing an asset group name"
    end

    add_study_to_assets(found_assets, study)

    # Create the order.  Ensure that the number of lanes is correctly set.
    sub_template      = find_template(details['template name'])
    number_of_lanes   = details.fetch('number of lanes', 1).to_i

    sub_template.new_order(attributes).tap do |new_order|
      new_order.request_type_multiplier do |multiplexed_request_type_id|
        new_order.request_options[:multiplier][multiplexed_request_type_id] = number_of_lanes
      end
    end
  rescue => e
    errors.add :spreadsheet, "There was a problem on row(s) #{details['rows']}: #{e.message}"
    nil
  end

  # Returns the SubmissionTemplate and checks that it is valid
  def find_template(template_name)
    template = SubmissionTemplate.find_by(name: template_name) or raise StandardError, "Cannot find template #{template_name}"
    raise(StandardError, "Template: '#{template_name}' is deprecated and no longer in use.") unless template.visible

    template
  end

  # This is used to present a list of successes
  def completed_submissions
    [@submission_ids, @completed_submissions]
  end
end
