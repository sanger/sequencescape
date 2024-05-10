# frozen_string_literal: true

# Handles the processing of polymorphic metadata for a study.
class Study::PolyMetadataHandler
  include ActiveModel::Validations

  # Add the attribute accessor for each polymorphic metadata key here.

  # @!attribute [rw] scrna_core_pbmc_donor_pooling_required_number_of_cells
  #   @return [Integer] The number of cells required for PBMC donor pooling.
  attr_accessor :scrna_core_pbmc_donor_pooling_required_number_of_cells

  # Add validations for each polymorphic metadata key here.

  validates :scrna_core_pbmc_donor_pooling_required_number_of_cells,
    numericality: { greater_than: 0, allow_blank: true }

  # Initializes a new instance of the PolyMetadataHandler class. The studies
  # controller creates an instance of this class in the create and update
  # actions and passes the study instance.
  #
  # @param study [Study] The study to handle polymorphic metadata for.
  # @return [void]
  def initialize(study)
    @study = study
  end

  # Processes the provided poly_metadta parameters. This involves three steps:
  # 1. Assigning the parameters to corresponding attributes.
  # 2. Validating the assigned attributes.
  # 3. Dispatching the parameters to their specific handler methods.
  # The parameters passed from the controller are solely poly_metadata keys and values.
  # This is because they are nested under the poly_metadata key in the form fields,
  # which allows for straightforward iterations within this class.
  #
  # @param params [Hash] The poly_metadata parameters to process.
  # @return [void]
  def process(params)
    assign_attributes(params)
    validate_attributes
    dispatch(params)
  end

  # Assigns the given parameters to attributes if they are defined.
  #
  # @param params [Hash] The parameters to assign.
  # @return [void]
  def assign_attributes(params)
    params.each do |key, value|
      send(:"#{key}=", value) if self.class.method_defined?(key)
    end
  end

  # Validates the assigned attributes. If any attributes are invalid, their
  # errors are added to the study's errors, and an ActiveRecord::RecordInvalid
  # exception is raised with the study as its record. Adding errors to the
  # study is important to render messages in the UI. Raising the specific
  # exception is important to rollback the active transaction.
  #
  # @return [void]
  # @raise [ActiveRecord::RecordInvalid] If any attributes are invalid.
  def validate_attributes
    return if valid?
      errors.each do |error|
        @study.errors.add(error.attribute, error.message)
      end
      raise ActiveRecord::RecordInvalid, @study
  end

  # Dispatches the given parameters by calling a handler method for each one
  # if it exists. The convention for the handler methods is to prefix the key
  # with 'handle_'. For example, if the key is
  # 'scrna_core_pbmc_donor_pooling_required_number_of_cells', the handler method
  # would be 'handle_scrna_core_pbmc_donor_pooling_required_number_of_cells'.
  #
  # @param params [Hash] The parameters to dispatch.
  # @return [void]
  def dispatch(params)
    params.each do |key, value|
      method = "handle_#{key}"
      send(method, value) if respond_to?(method)
    end
  end

  # Handles 'scrna_core_pbmc_donor_pooling_required_number_of_cells' parameter.
  # A blank value defaults to Limber's value. Limber will warn but allow
  # proceeding with the default value for the study. If a matching PolyMetadatum
  # exists with the same value as the parameter, the method exits early to avoid
  # redundant updates. Otherwise, a new PolyMetadatum is created or updated with
  # the new value, followed by a save operation.
  #
  # @param value [String] The value of the
  #   scrna_core_pbmc_donor_pooling_required_number_of_cells parameter.
  # @return [void]
  def handle_scrna_core_pbmc_donor_pooling_required_number_of_cells(value)
    key = 'scrna_core_pbmc_donor_pooling_required_number_of_cells'
    poly_metadatum = @study.poly_metadatum_by_key(key)

    # PolyMetadatum does not allow a blank value; delete the record instead.
    if value.blank?
      poly_metadatum.destroy! if poly_metadatum.present?
      return
    end

    # Do not update if the value is the same.
    return if poly_metadatum&.value == value

    # Create or update the PolyMetadatum.
    poly_metadatum ||= PolyMetadatum.new(key: key, metadatable: @study)
    poly_metadatum.value = value
    poly_metadatum.save!
    nil
  end
end
