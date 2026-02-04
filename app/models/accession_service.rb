# frozen_string_literal: true

# The EBI operates two key AccessionServices
#
# {AccessionService::ENAService}: Mostly non-human data, provides open access to uploaded data
# {AccessionService::EGAService}: Mostly for human data, provides managed access to uploaded data
#
# We also submit information to ArrayExpress, but this happens indirectly via the accession services above.
# @see https://www.ebi.ac.uk/ega/submission#which_archive
#
# Accessioning involves submitting metadata to an external database as XML files.
# This data receives a unique 'accession number' which we store in the database.
# These accession numbers can then be used in publications to allow external researchers
# access to the metadata.
#
# Accessionables
# --------------
# {Accessionable::Study}      Represents information about the study. Indicates WHY the samples have been sequenced.
#                             Maps to a Sequencescape {Study}.
# {Accessionable::Submission} Wrapper object required by the submission service. We use one per accessionable.
# The following are associated with EGA studies.
# {Accessionable::Dac}    Data access committee. Information about who to contact to gain access to the data. (EGA)
# {Accessionable::Policy} Details about how the data may be used. (EGA)
#
# Accessioning of samples has been fully migrated to {Accession 'a separate accession library'}
module AccessionService
  # Define custom error classes for the AccessionService
  AccessionServiceError = Class.new(StandardError)
  AccessionValidationFailed = Class.new(AccessionServiceError)
  NumberNotRequired = Class.new(AccessionServiceError)
  NumberNotGenerated = Class.new(AccessionServiceError)

  CENTER_NAME = 'SC' # TODO: [xxx] use confing file
  PROTECT = 'protect'
  HOLD = 'hold'

  # Returns an instance of the appropriate accession service for a study based on its data release strategy.
  # Open studies use ENA, managed studies use EGA, and others use NoService.
  #
  # @param study [Study] The study for which to select the accession service.
  # @return [AccessionService::BaseService] The corresponding accession service instance.
  def self.select_for_study(study)
    case study.data_release_strategy
    when 'open'
      AccessionService::ENAService.new
    when 'managed'
      AccessionService::EGAService.new
    else
      AccessionService::NoService.new(study)
    end
  end
end
