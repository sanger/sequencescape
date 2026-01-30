# frozen_string_literal: true

# Helper methods to determine accessionablity and permissions at application level.
#
# See Study#samples_accessionable? for study level.
# See Sample#should_be_accessioned? for sample level.
module AccessionHelper
  # Checks if accessioning is enabled in this environment.
  # This is controlled by a flag in the deployment project.
  # @return [Boolean] true if accessioning is enabled, false otherwise
  def accessioning_enabled?
    configatron.accession_samples
  end

  # Checks if the current user is permitted to accession the given object.
  # @param object [Sample, Study] the object to check permissions for
  # @return [Boolean] true if the user has permission, false otherwise
  def permitted_to_accession?(object)
    can?(:accession, object) || false
  end
end
