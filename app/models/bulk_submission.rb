class ActiveRecord::Base
  class << self
    def find_by_id_or_name(id, name)
      return find(id) unless id.blank?
      raise StandardError, "Must specify at least ID or name" if name.blank?
      find_by_name(name) or raise ActiveRecord::RecordNotFound, "Cannot find #{self.name} #{name.inspect}"
    end

    def find_all_by_id_or_name(ids, names)
      return Array(find(*ids)) unless ids.blank?
      raise StandardError, "Must specify at least an ID or a name" if names.blank?
      find_all_by_name(names).tap do |found|
        missing = names - found.map(&:name)
        raise ActiveRecord::RecordNotFound, "Could not find #{self.name} with names #{missing.inspect}" unless missing.blank?
      end
    end
  end
end

class Array
  def comma_separate_field_list(*fields)
    map { |row| fields.map { |field| row[field] } }.flatten.delete_if(&:blank?).join(',')
  end
end

class BulkSubmission < ActiveRecord::Base

  # Using table-less pattern - all columns are specified in the model rather than the DBMS
  # see http://codetunes.com/2008/07/20/tableless-models-in-rails
  def self.columns() @columns ||= []; end

  def self.column(name, sql_type = nil, default = nil, null = true)
    columns << ActiveRecord::ConnectionAdapters::Column.new(name.to_s, default, sql_type.to_s, null)
  end

  # The only column is the spreadsheet, which needs to be validated before submitting in one big transaction
  column :spreadsheet, :binary

  validates_presence_of :spreadsheet
  validate :process_file

  def process_file
    # Slightly inelegant file-type checking
    #TODO (jr) Find a better way of verifying the CSV file?
    unless spreadsheet.blank?
      if File.size(spreadsheet) == 0
        errors.add(:spreadsheet, "The supplied file was empty")
      else
        if /^.*\.csv$/.match(spreadsheet.original_filename)
          process
        else
          errors.add(:spreadsheet, "The supplied file was not a CSV file")
        end
      end
    end
  rescue FasterCSV::MalformedCSVError
      errors.add(:spreadsheet, "The supplied file was not a valid CSV file (try opening it with MS Excel)")
  end

  def headers
    @headers ||= @csv_rows.fetch(header_index) unless header_index.nil?
  end
  private :headers

  def csv_data_rows
    @csv_rows.slice(header_index+1...@csv_rows.length)
  end
  private :csv_data_rows

  def header_index
    @header_index ||= @csv_rows.each_with_index do |row, index|
      next if index == 0 && row[0] == "This row is guidance only"
      return index if header_row?(row)
    end
    # We've got through all rows without finding a header
    errors.add(:spreadsheet, "The supplied file does not contain a valid header row (try downloading a template)")
    nil
  end
  private :header_index

  def start_row
    header_index + 2
  end
  private :start_row

  def header_row?(row)
    row.each {|col| col.try(:downcase!)}
    (row & COMMON_FIELDS).length > 0
  end
  private :header_row?

  def valid_header?
    return false if headers.nil?
    return true if headers.include? "submission name"
    errors.add :spreadsheet, "You submitted an incompatible spreadsheet. Please ensure your spreadsheet contains the 'submission name' column"
    false
  end

  def spreadsheet_valid?
    valid_header?
    errors.count == 0
  end
  private :spreadsheet_valid?

  def process
    # Store the details of the successful submissions so the user can be presented with a summary
    @submission_ids = []
    @completed_submissions = {}
    @csv_rows = FasterCSV.parse(spreadsheet.read)

    if spreadsheet_valid?
      submission_details = submission_structure
      # Within a single transaction process each of the rows of the CSV file as a separate submission.  Any name
      # fields need to be mapped to IDs, and the 'assets' field needs to be split up and processed if present.
      ActiveRecord::Base.transaction do
        submission_details.each do |submissions|
          submissions.each do |submission_name,orders|
            user = User.find_by_login(orders.first['user login'])
            if user.nil?
              errors.add :spreadsheet, "Cannot find user #{orders.first["user login"].inspect}"
              next
            end

            begin
              submission = Submission.create!(:name=>submission_name, :user => user, :orders => orders.map(&method(:prepare_order)).compact)
              submission.built!
              # Collect successful submissions
              @submission_ids << submission.id
              @completed_submissions[submission.id] = "Submission #{submission.id} built (#{submission.orders.count} orders)"
            rescue Quota::Error => exception
              errors.add :spreadsheet, "There was a quota problem: #{exception.message}"
            end
          end
        end

        # If there are any errors then the transaction needs to be rolled back.
        raise ActiveRecord::Rollback if errors.count > 0
      end

    end
  end #process

  COMMON_FIELDS = [
    # Needed to construct the submission ...
    'template name',
    'study id', 'study name',
    'project id', 'project name', 'submission name',
    'user login',

    # Needed to identify the assets and what happens to them ...
    'plate barcode', 'plate well',
    'asset group id', 'asset group name',
    'fragment size from', 'fragment size to',
    'read length',
    'library type',
    'bait library', 'bait library name',
    'comments',
    'number of lanes'
  ]

  def validate_entry(header,pos,row,index)
    return [header, row[pos].try(:strip)] unless header.nil? && row[pos].present?
    errors.add(:spreadsheet, "Row #{index}, column #{pos+1} contains data but no heading.")
  end
  private :validate_entry

  # Process CSV into a structure
  #  this creates an array containing a hash for each distinct "submission name"
  #    "submission name" => array of orders
  #    where each order is a hash of headers to values (grouped by "asset group name")
  def submission_structure
    csv_data_rows.each_with_index.map do |row, index|
      Hash[headers.each_with_index.map { |header, pos| validate_entry(header,pos,row,index+start_row) }].merge('row' => index+start_row)
    end.group_by do |details|
      details['submission name']
    end.map do |submission_name, rows|
      order = rows.group_by do |details|
        details["asset group name"]
      end.map do |group_name, rows|
        Hash[COMMON_FIELDS.map { |f| [ f, rows.first[f] ] }].tap do |details|
          details['rows']          = rows.comma_separate_field_list('row')
          details['asset ids']     = rows.comma_separate_field_list('asset id', 'asset ids')
          details['asset names']   = rows.comma_separate_field_list('asset name', 'asset names')
          details['plate well']    = rows.comma_separate_field_list('plate well')
        end.delete_if { |_,v| v.blank? }
      end
      Hash[submission_name, order]
    end
  end

  # Returns an order for the given details
  def prepare_order(details)
    begin

      # Retrieve common attributes
      study   = Study.find_by_id_or_name(details['study id'], details['study name'])
      project = Project.find_by_id_or_name(details['project id'], details['project name'])
      user    = User.find_by_login(details['user login']) or raise StandardError, "Cannot find user #{details['user login'].inspect}"

      # The order attributes are initially
      attributes = {
        :study   => study,
        :project => project,
        :user => user,
        :comments => details['comments'],
        :request_options => {
          :read_length  => details['read length']
        }
      }

      attributes[:request_options]['library_type']                  = details['library type']       unless details['library type'].blank?
      attributes[:request_options]['fragment_size_required_from']   = details['fragment size from'] unless details['fragment size from'].blank?
      attributes[:request_options]['fragment_size_required_to']     = details['fragment size to']   unless details['fragment size to'].blank?
      attributes[:request_options][:bait_library_name]              = details['bait library name']  unless details['bait library name'].blank?
      attributes[:request_options][:bait_library_name]            ||= details['bait library']       unless details['bait library'].blank?

      # Deal with the asset group: either it's one we should be loading, or one we should be creating.
      begin
        attributes[:asset_group] = study.asset_groups.find_by_id_or_name(details['asset group id'], details['asset group name'])

      rescue ActiveRecord::RecordNotFound => exception

        attributes[:asset_group_name] = details['asset group name']

        # Locate either the assets by name or ID, or find the plate and it's well
        if not details['plate barcode'].blank? and not details['plate well'].blank?
          match = /^([A-Z]{2})(\d+)[A-Z]$/.match(details['plate barcode']) or raise StandardError, "Plate barcode should be human readable (e.g. DN111111K)"
          prefix = BarcodePrefix.find_by_prefix(match[1]) or raise StandardError, "Cannot find barcode prefix #{match[1].inspect} for #{details['rows']}"
          plate  = Plate.find_by_barcode_prefix_id_and_barcode(prefix.id, match[2]) or raise StandardError, "Cannot find plate with barcode #{details['plate barcode']} for #{details['rows']}"

          wells, well_locations = [], details['plate well'].split(',').map(&:strip)
          plate.wells.walk_in_column_major_order { |well, _| wells << well if well_locations.include?(well.map.description) }
          raise StandardError, "Too few wells found for #{details['rows']}: #{wells.map(&:map).map(&:description).inspect}" if wells.size != well_locations.size
          attributes[:assets] = wells

        else
          asset_ids, asset_names = details.fetch('asset ids', '').split(','), details.fetch('asset names', '').split(',')
          attributes[:assets]    = Asset.find_all_by_id_or_name(asset_ids, asset_names).uniq

          assets_found, expecting = attributes[:assets].map { |asset| "#{asset.name}(#{asset.id})" }, asset_ids.size + asset_names.size
          raise StandardError, "Too few assets found for #{details['rows']}: #{assets_found.inspect}"  if assets_found.size < expecting
          raise StandardError, "Too many assets found for #{details['rows']}: #{assets_found.inspect}" if assets_found.size > expecting

        end

        assets_not_in_study = attributes[:assets].select { |asset| not asset.aliquots.map(&:sample).map(&:studies).flatten.uniq.include?(study) }
        raise StandardError, "Assets not in study #{study.name.inspect} for #{details['rows']}: #{assets_not_in_study.map(&:display_name).inspect}" unless assets_not_in_study.empty?

      end

      # Create the order.  Ensure that the number of lanes is correctly set.
      template          = find_template(details['template name'])
      request_types     = RequestType.all(:conditions => { :id => template.submission_parameters[:request_type_ids_list].flatten })
      lane_request_type = request_types.detect(&:targets_lanes?)
      number_of_lanes   = details.fetch('number of lanes', 1).to_i
      attributes[:request_options][:multiplier] = { lane_request_type.id => number_of_lanes } if lane_request_type.present?

      return template.new_order(attributes)
    rescue => exception
      errors.add :spreadsheet, "There was a problem on row(s) #{details['rows']}: #{exception.message}"
      nil
    end
  end

  # Returns the SubmissionTemplate and checks that it is valid
  def find_template(template_name)
    template = SubmissionTemplate.find_by_name(template_name) or raise StandardError, "Cannot find template #{template_name}"
    raise(StandardError, "Template: '#{template_name}' is deprecated and no longer in use.") unless template.visible
    template
  end

  # This is used to present a list of successes
  def completed_submissions
    return @submission_ids, @completed_submissions
  end

end
