# frozen_string_literal: true

# Assigns library information to the {Aliquot aliquots} when the {Plate} is passed.
# This behaviour is now mostly handled by the library creation requests themselves
module PlatePurpose::Library
  def self.included(base)
    base.class_eval do
      include PlatePurpose::WorksOnLibraryRequests
    end
  end

  STATES_TO_ASSIGN_LIBRARY_INFORMATION = %w[started passed].freeze

  # Performs the standard transition_to of the containing class and then
  # assigns library information to the wells
  def transition_to(plate, state, user, contents = nil, customer_accepts_responsibility = false)
    super
    assign_library_information_to_wells(plate) if STATES_TO_ASSIGN_LIBRARY_INFORMATION.include?(state)
  end

  # Ensure that the library information within the aliquots of the well is correct.
  def assign_library_information_to_wells(plate)
    each_well_and_its_library_request(plate) do |well, library_request|
      library_type, insert_size = library_request.library_type, library_request.insert_size

      well.aliquots.each do |aliquot|
        aliquot.library      ||= well
        aliquot.library_type ||= library_type
        aliquot.insert_size  ||= insert_size
        aliquot.save!
      end
    end
  end
  private :assign_library_information_to_wells
end
