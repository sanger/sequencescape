class PresenterSkeleton
  class_inheritable_reader :attributes
  write_inheritable_attribute :attributes,  []

  def initialize(user, submission_attributes = {})
    submission_attributes = {} if submission_attributes.blank?

    @user = user

    attributes.each do |attribute|
      send("#{attribute}=", submission_attributes[attribute])
    end

  end

  # id accessors need to be explicitly defined...
  def id
    @id
  end

  def id=(submission_id)
    @id = submission_id
  end

  def lanes_of_sequencing
    return lanes_from_request_options if %{building pending}.include?(submission.state)
    lanes_from_request_counting
  end

  def lanes_from_request_options
    library_request       = RequestType.find(order.request_types.first)
    sequencing_request    = RequestType.find(order.request_types.last)
    sequencing_multiplier = order.request_options.fetch('multiplier', {}).fetch(sequencing_request.id.to_s, 1).to_i

    if library_request.for_multiplexing?
      sequencing_multiplier
    else
      order.assets.count * sequencing_multiplier
    end
  end
  private :lanes_from_request_options

  def lanes_from_request_counting
    submission.requests.select do |r|
      r.class.ancestors.include?(SequencingRequest)
    end.count
  end
  private :lanes_from_request_counting

  def method_missing(name, *args, &block)
    name_without_assignment = name.to_s.sub(/=$/, '').to_sym
    return super unless attributes.include?(name_without_assignment)

    instance_variable_name = :"@#{name_without_assignment}"
    return instance_variable_get(instance_variable_name) if name_without_assignment == name.to_sym
    instance_variable_set(instance_variable_name, args.first)
  end
  protected :method_missing
end

class SubmissionCreater < PresenterSkeleton
  SubmissionsCreaterError  = Class.new(StandardError)
  IncorrectParamsException = Class.new(SubmissionsCreaterError)
  InvalidInputException    = Class.new(SubmissionsCreaterError)

  # Remove this Exception if you enable multiple orders per submission
  MultipleOrdersException = Class.new(Exception)

  write_inheritable_attribute :attributes,  [
    :id,
    :template_id,
    :sample_names_text,
    :barcodes_wells_text,
    :study_id,
    :submission_id,
    :project_name,
    :plate_purpose_id,
    :lanes_of_sequencing_required,
    :comments,
    :orders,
    :order_params,
    :asset_group_id
  ]


  def build_submission!
    begin
      submission.built!

    rescue ActiveRecord::RecordInvalid => exception
      exception.record.errors.full_messages.each do |message|
        submission.errors.add_to_base(message)
      end
    end
  end

  def find_asset_group
    AssetGroup.find(asset_group_id) if asset_group_id.present?
  end

  # Returns the either the first order associated with the submission or
  # creates a new blank order.
  def order
    return @order if @order.present?
    return submission.orders.first if submission.present?

    @order = create_order
  end

  def create_order
    new_order = template.new_order(
      :study           => study,
      :project         => project,
      :user            => @user,
      :request_options => order_params,
      :comments        => comments
    )

    new_order.request_type_multiplier do |sequencing_request_type_id|
      new_order.request_options['multiplier'][sequencing_request_type_id] = (lanes_of_sequencing_required || 1)
    end if order_params

    new_order
  end
  private :create_order

  def order_params
    @order_params[:multiplier] = {} if @order_params && @order_params[:multiplier].nil?
    @order_params
  end

  def order_fields
    if order.input_field_infos.flatten.empty?
      order.request_type_ids_list = order.request_types.map { |rt| [rt] }
    end

    order.input_field_infos
  end

  # Return the submission's orders or a blank array
  def orders
    return [] unless submission.present?
    submission.try(:orders).map { |o| OrderPresenter.new(o) }
  end

  def project
    @project ||= Project.find_by_name(@project_name)
  end

  # Creates a new submission and adds an initial order on the submission using
  # the parameters
  def save
    begin
      ActiveRecord::Base.transaction do
        # Add assets to the order...
        new_order = create_order.tap { |o| o.update_attributes!(order_assets) }

        if submission.present?
          # This code shouldn't get run, as the client should stop this but...
          # This exception is thrown if we try to add multiple orders to a submission.
          # The submission should be destroyed if we delete the last order on it so
          # we shouldn't see any empty submissions.
          # Remove the raise and recue block to enable multiple submissions.
          # You'll also need to renable them in the submission.js file.
          raise MultipleOrdersException


          # uncomment this line to enable multiple orders
          # submission.orders << new_order
        else
          @submission = new_order.create_submission(:user => order.user)
        end

        new_order.save!
        @order = new_order
      end


    rescue MultipleOrdersException => exception
      order.errors.add_to_base('Sorry, multiple orders per submission are not supported at the current time.')
    rescue Quota::Error => quota_exception
      order.errors.add_to_base(quota_exception.message)
    rescue InvalidInputException => input_exception
      order.errors.add_to_base(input_exception.message)
    rescue IncorrectParamsException => exception
      order.errors.add_to_base(exception.message)
    rescue ActiveRecord::RecordInvalid => exception
      exception.record.errors.full_messages.each do |message|
        order.errors.add_to_base(message)
      end
    end

    # Having got through that lot, return whether the save was successful or not
    order.errors.empty?
  end

  def order_assets
    input_methods = [ :asset_group_id, :sample_names_text, :barcodes_wells_text ].select { |input_method| send(input_method).present? }

    raise InvalidInputException, "No Samples found" if input_methods.empty?
    raise InvalidInputException, "Samples cannot be added from multiple sources at the same time." unless input_methods.size == 1


    return case input_methods.first
      when :asset_group_id    then { :asset_group => find_asset_group }
      when :sample_names_text then
        {
          :assets => wells_on_specified_plate_purpose_for(
            plate_purpose,
            find_samples_from_text(sample_names_text)
          )
        }
      when :barcodes_wells_text then
        {
          :assets => find_assets_from_text(barcodes_wells_text)
        }

      else raise StandardError, "No way to determine assets for input choice #{input_methods.first}"
    end
  end

  # This is a legacy of the old controller...
  def wells_on_specified_plate_purpose_for(plate_purpose, samples)
    samples.map do |sample|
      sample.wells.all(:include => :plate).detect { |well| well.plate.present? and (well.plate.plate_purpose_id == plate_purpose.id) } or
        raise InvalidInputException, "No #{plate_purpose.name} plate found with sample: #{sample.name}"
    end
  end

  def plate_purpose
    @plate_purpose ||= PlatePurpose.find(plate_purpose_id)
  end

  # Returns Samples based on Sample name or Sanger ID
  # This is a legacy of the old controller...
  def find_samples_from_text(sample_text)
    names = sample_text.lines.map(&:chomp).reject(&:blank?).map(&:strip)

    samples = Sample.all(
      :include => :assets,
      :conditions => [ 'name IN (:names) OR sanger_sample_id IN (:names)', { :names => names } ]
    )

    name_set  = Set.new(names)
    found_set = Set.new(samples.map { |s| [ s.name, s.sanger_sample_id ] }.flatten)
    not_found = name_set - found_set
    raise InvalidInputException, "#{Sample.table_name} #{not_found.to_a.join(", ")} not found" unless not_found.empty?
    return samples
  end
  private :find_samples_from_text

  def find_assets_from_text(assets_text)
    plates_wells = assets_text.lines.map(&:chomp).reject(&:blank?).map(&:strip)

    plates_wells.map do |plate_wells|
      plate_barcode, well_locations = plate_wells.split(':')
      begin
        plate = Plate.find_from_machine_barcode(Barcode.human_to_machine_barcode(plate_barcode))
      rescue Barcode::InvalidBarcode => exception
        raise InvalidInputException, "Invalid Barcode #{plate_barcode}: #{exception}"
      end
      raise InvalidInputException, "No plate found for barcode #{plate_barcode}." if plate.nil?
      well_array = (well_locations||'').split(',').reject(&:blank?).map(&:strip)

      find_wells_in_array(plate,well_array)
    end.flatten
  end
  private :find_assets_from_text

  def find_wells_in_array(plate,well_array)
    return plate.wells.with_aliquots if well_array.empty?
    well_array.map do |map_description|
      case map_description
      when /^[a-z,A-Z][0-9]+$/ # A well
        well = plate.find_well_by_name(map_description)
        if well.nil? or well.aliquots.empty?
          raise InvalidInputException, "Well #{map_description} on #{plate.sanger_human_barcode} does not exist or is empty."
        else
          well
        end
      when /^[a-z,A-Z]$/ # A row
        plate.wells.with_aliquots.in_plate_row(map_description,plate.size)
      when /^[0-9]+$/ # A column
        plate.wells.with_aliquots.in_plate_column(map_description,plate.size)
      else
        raise InvalidInputException, "#{map_description} is not a valid well location"
      end
    end
  end
  private :find_wells_in_array

  def study
    @study ||= (Study.find(@study_id) if @study_id.present?)
  end

  def studies
    @studies ||= [ study ] if study.present?
    @studies ||= @user.interesting_studies.sort {|a,b| a.name <=> b.name }
  end

  def submission
    return nil unless id.present? || @submission
    @submission ||= Submission.find(id)
  end

  # Returns the SubmissionTemplate (OrderTemplate) to be used for this Submission.
  def template
    # We can't get the template from a saved order, have to find by name.... :(
    @template =  SubmissionTemplate.find_by_name(order.template_name) if try(:submission).try(:orders).present?
    @template ||= SubmissionTemplate.find(@template_id)
  end

  def templates
    @templates ||= SubmissionTemplate.visible
  end

  def template_id
    submission.try(:orders).try(:first).try(:id)
  end

  # Returns an array of all the names of active projects associated with the
  # current user.
  def user_valid_projects
    @user_active_projects ||= @user.sorted_valid_project_names_and_ids.map(&:first)
  end

  def url(view)
    view.send(:submission_path, submission.present? ? submission : { :id => 'DUMMY_ID' })
  end
end

class SubmissionPresenter < PresenterSkeleton
  write_inheritable_attribute :attributes, [ :id ]

  def submission
    @submission ||= Submission.find(id)
  end

  def template_name
    submission.orders.first.template_name
  end

  def order
    submission.orders.first
  end

  # Deleting a Submission should also delete all associated Orders.
  def destroy
    submission.orders.destroy_all
    submission.destroy
  end

end

