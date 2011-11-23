class ActiveRecord::Base
  class << self
    def find_by_id_or_name(id, name)
      return find(id) unless id.blank?
      raise StandardError, "Must specify at least ID or name" if name.blank?
      find_by_name(name) or raise ActiveRecord::RecordNotFound, "Cannot find #{self.name} #{name.inspect}"
    end

    def find_all_by_id_or_name(ids, names)
      return find(*ids) unless ids.blank?
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
          process FasterCSV.parse(spreadsheet.read)
        else
          errors.add(:spreadsheet, "The supplied file was not a CSV file")
        end
      end
    end
  rescue FasterCSV::MalformedCSVError
      errors.add(:spreadsheet, "The supplied file was not a valid CSV file (try opening it with MS Excel)")
  end

  COMMON_FIELDS = [
    # Needed to construct the submission ...
    'template name',
    'study id', 'study name',
    'project id', 'project name',
    'user login',

    # Needed to identify the assets and what happens to them ...
    'plate barcode', 'plate well',
    'asset group id', 'asset group name',
    'fragment size from', 'fragment size to',
    'read length',
    'library type',
    'comments',
    'number of lanes'
  ]
  
  def process(csv_rows)
     @submissions = []
     @submission_details = {}
  
    # Ensure that the keys of the rows are downcased for consistency.
    # Group each of the rows by the asset group name, as this governs the submissions that are being created.
    # Then we take the common details and essentially merge the assets into a list.
    
    if (csv_rows[0][0] == "This row is guidance only")
      help = csv_rows.shift
      headers = csv_rows.shift.map(&:downcase)
    else
      headers = csv_rows.shift.map(&:downcase)
    end
    
    # Detect that the CSV does not have any items from our known fields in the first row using an intersection
    if (headers & COMMON_FIELDS).length == 0
      errors.add(:spreadsheet, "The supplied file does not contain a valid header row (try downloading a template)")
      
    elsif not headers.include? "submission name"
      errors.add :spreadsheet, "You submitted an incompatible spreadsheet. Please ensure your spreadsheet contains the 'submission name' column"
      
    else
      submission_details = csv_rows.each_with_index.map do |row, index|
        Hash[headers.each_with_index.map { |header, pos| [ header, row[pos].try(:strip) ] }].merge('row' => index+2)
      end.group_by do |details|
        details['asset group name']
      end.map do |group_name, rows|
        Hash[COMMON_FIELDS.map { |f| [ f, rows.first[f] ] }].tap do |details|
          details['rows']          = rows.comma_separate_field_list('row')
          details['asset ids']     = rows.comma_separate_field_list('asset id', 'asset ids')
          details['asset names']   = rows.comma_separate_field_list('asset name', 'asset names')
          details['plate well']    = rows.comma_separate_field_list('plate well')
        end.delete_if { |_,v| v.blank? }
      end
    
    # Rails.logger.debug(submission_details.inspect)
      # Within a single transaction process each of the rows of the CSV file as a separate submission.  Any name
      # fields need to be mapped to IDs, and the 'assets' field needs to be split up and processed if present.
      ActiveRecord::Base.transaction do
        failures = false

        submission_details.each_with_index do |details, submission_row|
          begin
            # Map the various columns correctly to objects ...
            study = Study.find_by_id_or_name(details['study id'], details['study name'])
            attributes = {
              :study   => study,
              :project => Project.find_by_id_or_name(details['project id'], details['project name']),

              :comments => details['comments'],
              :request_options => {
                :read_length                 => details['read length'],
                :library_type                => details['library type'],
              }
            }
            number_of_lanes = details.fetch('number of lanes', 1).to_i
            attributes[:request_options][:fragment_size_required_from] = details['fragment size from'] unless details['fragment size from'].blank?
            attributes[:request_options][:fragment_size_required_to]   = details['fragment size to']   unless details['fragment size to'].blank?

            # User lookup ...
            attributes[:user] = User.find_by_login(details['user login']) or raise StandardError, "Cannot find user #{details['user login'].inspect}"


            # Deal with the asset group: either it's one we should be loading, or one we should be creating.
            begin
              attributes[:asset_group] = study.asset_groups.find_by_id_or_name(details['asset group id'], details['asset group name'])
            rescue ActiveRecord::RecordNotFound => exception
              # puts "Could not find asset group, assuming it needs to be created for rows #{details['rows']}"

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
              raise StandardError, "Assets not in study for #{details['rows']}: #{assets_not_in_study.inspect}" unless assets_not_in_study.empty?

              puts "\tDebugging info: assets found for #{details['rows']}: #{assets_found.inspect}" if ENV['DO_NOTHING']
            end

            # Create and build the submission.  Ensure that the number of lanes is correctly set.
            template          = SubmissionTemplate.find_by_name(details['template name']) or raise StandardError, "Cannot find template #{details['template name']}"
            request_types     = RequestType.all(:conditions => { :id => template.submission_parameters[:request_type_ids_list].flatten })
            lane_request_type = request_types.detect { |t| t.target_asset_type == 'Lane' or t.name =~ /\ssequencing$/ }
            attributes[:request_options][:multiplier] = { lane_request_type.id => number_of_lanes } if lane_request_type.present?

            submission = Submission.build!(attributes.merge(:template => template))
            
            # Collect the IDs of successful submissions
            @submissions.push submission.id
            @submission_details[submission.id] = "Submission #{submission.id} built from rows #{details['rows']} (should make #{number_of_lanes} lanes)"
          rescue ArgumentError
            raise
          rescue => exception
            errors.add :spreadsheet, "There was a problem on row(s) #{details['rows']}: #{exception.message}"
           
            failures = true
          rescue Quota::Error => exception
                                errors.add :spreadsheet, "There was a quota problem: #{exception.message}"
          
          end
          
          
        end
        
        # If there are any errors then the transaction needs to be rolled back.
        raise ActiveRecord::Rollback if failures
      end
      
    end
  end #process
  
  def completed_submissions
    return @submissions, @submission_details
  end
  


end
