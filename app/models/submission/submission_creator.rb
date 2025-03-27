# frozen_string_literal: true

require 'aasm'

# Used to handle the rendering of the submission/order pages in the
# web-based submission interface
class Submission::SubmissionCreator < Submission::PresenterSkeleton # rubocop:todo Metrics/ClassLength
  SubmissionsCreaterError = Class.new(StandardError)
  IncorrectParamsException = Class.new(SubmissionsCreaterError)
  InvalidInputException = Class.new(SubmissionsCreaterError)

  self.attributes = %i[
    id
    template_id
    sample_names_text
    barcodes_wells_text
    study_id
    submission_id
    project_name
    plate_purpose_id
    lanes_of_sequencing_required
    comments
    orders
    order_params
    asset_group_id
    pre_capture_plex_group
    gigabases_expected
    priority
  ]

  def build_submission!
    submission.built!
  rescue AASM::InvalidTransition
    submission.errors.add(:base, 'Submissions can not be edited once they are submitted for building.')
  rescue ActiveRecord::RecordInvalid => e
    e.record.errors.full_messages.each { |message| submission.errors.add(:base, message) }
  rescue Submission::ProjectValidation::Error => e
    submission.errors.add(:base, e.message)
  end

  def per_order_settings
    %i[pre_capture_plex_level gigabases_expected customer_accepts_responsibility]
  end

  def find_asset_group
    AssetGroup.find(asset_group_id) if asset_group_id.present?
  end

  # Returns the either the first order associated with the submission or
  # creates a new blank order.
  # @note Following the creation of an order, this will actually be the last order
  # created.
  def order
    return @order if @order.present?
    return submission.orders.first if submission.present?

    @order = create_order
  end

  delegate :cross_compatible?, to: :order

  def order_params
    @order_params = @order_params.to_hash if @order_params.instance_of?(ActiveSupport::HashWithIndifferentAccess)
    @order_params[:multiplier] = ActiveSupport::HashWithIndifferentAccess.new if @order_params &&
      @order_params[:multiplier].nil?
    @order_params
  end

  def pre_capture_plex_level
    order.input_field_infos.detect { |ifi| ifi.key == :pre_capture_plex_level }&.default_value
  end

  def order_fields
    order.request_type_ids_list = order.request_types.zip if order.input_field_infos.flatten.empty?
    order.input_field_infos.reject { |info| per_order_settings.include?(info.key) }
  end

  # Return the submission's orders or a blank array
  def orders
    return [] if submission.blank?

    submission.try(:orders).map { |o| Submission::OrderPresenter.new(o) }
  end

  def project
    @project ||= Project.find_by(name: @project_name)
  end

  # Creates a new submission and adds an initial order on the submission using
  # the parameters
  # rubocop:todo Metrics/MethodLength
  def save # rubocop:todo Metrics/AbcSize
    begin
      ActiveRecord::Base.transaction do
        # Add assets to the order...
        new_order = create_order.tap { |o| o.update!(order_assets) }

        if submission.present?
          # The submission should be destroyed if we delete the last order on it so
          # we shouldn't see any empty submissions.

          submission.orders << new_order
        else
          @submission = new_order.create_submission(user: order.user, priority: priority)
        end

        new_order.save!
        @order = new_order
      end
    rescue Submission::ProjectValidation::Error => e
      order.errors.add(:base, e.message)
    rescue SubmissionsCreaterError, Asset::Finder::InvalidInputException => e
      order.errors.add(:base, e.message)
    rescue ActiveRecord::RecordInvalid => e
      e.record.errors.full_messages.each { |message| order.errors.add(:base, message) }
    end

    # Having got through that lot, return whether the save was successful or not
    order.errors.empty?
  end

  # rubocop:enable Metrics/MethodLength

  # this is more order_receptacles, asset_group is actually receptacle group
  # rubocop:todo Metrics/MethodLength
  def order_assets # rubocop:todo Metrics/AbcSize
    input_methods =
      %i[asset_group_id sample_names_text barcodes_wells_text].select { |input_method| send(input_method).present? }

    raise InvalidInputException, 'No Samples found' if input_methods.empty?
    unless input_methods.size == 1
      raise InvalidInputException, 'Samples cannot be added from multiple sources at the same time.'
    end

    case input_methods.first
    when :asset_group_id
      { asset_group: find_asset_group }
    when :sample_names_text
      { assets: wells_on_specified_plate_purpose_for(plate_purpose, find_samples_from_text(sample_names_text)) }
    when :barcodes_wells_text
      { assets: find_assets_from_text(barcodes_wells_text) }
    else
      raise StandardError, "No way to determine assets for input choice #{input_methods.first}"
    end
  end

  # rubocop:enable Metrics/MethodLength

  # This is a legacy of the old controller...
  def wells_on_specified_plate_purpose_for(plate_purpose, samples)
    samples.map do |sample|
      # Prioritise the newest well

      sample.wells.on_plate_purpose(plate_purpose).order(id: :desc).first ||
        raise(InvalidInputException, "No #{plate_purpose.name} plate found with sample: #{sample.name}")
    end
  end

  def cross_project
    false
  end

  def cross_study
    false
  end

  def plate_purpose
    @plate_purpose ||= PlatePurpose.find(plate_purpose_id)
  end

  def study
    @study ||= (Study.find(@study_id) if @study_id.present?)
  end

  def studies
    @studies ||= [study] if study.present?
    @studies ||= @user.interesting_studies.alphabetical
  end

  def submission
    return nil unless id.present? || @submission

    @submission ||= Submission.find(id)
  end

  # Returns the SubmissionTemplate (OrderTemplate) to be used for this Submission.
  def template
    # We can't get the template from a saved order, have to find by name.... :(
    @template = SubmissionTemplate.find_by(name: order.template_name) if try(:submission).try(:orders).present?
    @template ||= SubmissionTemplate.find(@template_id)
  end

  def product_lines
    SubmissionTemplate.grouped_by_product_lines
  end

  def template_id
    submission.try(:orders).try(:first).try(:id)
  end

  # Returns an array of all the names of active projects associated with the
  # current user.
  def user_valid_projects
    @user_valid_projects ||= Project.accessible_by(current_ability, :create_submission).valid
  end

  def current_ability
    @current_ability ||= Ability.new(@user)
  end

  def url(view)
    view.send(:submission_path, submission.presence || { id: 'DUMMY_ID' })
  end

  def template_name
    submission.orders.first.template_name
  end

  private

  def create_order # rubocop:todo Metrics/AbcSize
    order_role = OrderRole.find_by(role: order_params.delete('order_role')) if order_params.present?
    new_order =
      template.new_order(
        study: study,
        project: project,
        user: @user,
        request_options: order_params,
        comments: comments,
        pre_cap_group: pre_capture_plex_group,
        order_role: order_role
      )
    if order_params
      new_order.request_type_multiplier do |sequencing_request_type_id|
        new_order.request_options[:multiplier][sequencing_request_type_id] = (lanes_of_sequencing_required || 1)
      end
    end

    new_order
  end

  # Returns Samples based on Sample name or Sanger ID
  # This is a legacy of the old controller...
  def find_samples_from_text(sample_text)
    names = sample_text.split(/\s+/)
    samples = Sample.includes(:assets).where(['name IN (:names) OR sanger_sample_id IN (:names)', { names: }])

    name_set = Set.new(names)
    found_set = Set.new(samples.map { |s| [s.name, s.sanger_sample_id] }.flatten)
    not_found = name_set - found_set
    raise InvalidInputException, "#{Sample.table_name} #{not_found.to_a.join(', ')} not found" unless not_found.empty?

    samples
  end

  def find_assets_from_text(assets_text)
    plates_wells = assets_text.split(/\s+/)
    Asset::Finder.new(plates_wells).resolve
  end
end
