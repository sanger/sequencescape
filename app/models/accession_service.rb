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
# {Accessionable::Sample}     Represents information about the sample, maps to a Sequencescape {Sample}.
# {Accessionable::Study}      Represents information about the study. Indicates WHY the samples have been sequenced.
#                             Maps to a Sequencescape {Study}.
# {Accessionable::Submission} Wrapper object required by the submission service. We use one per accessionable.
# The following are associated with EGA studies.
# {Accessionable::Dac}    Data access committee. Information about who to contact to gain access to the data. (EGA)
# {Accessionable::Policy} Details about how the data may be used. (EGA)
#
# Accessioning of samples has been partially migrated to {Accession 'a separate accession library'}
module AccessionService
  # Define custom error classes for the AccessionService
  AccessionServiceError = Class.new(StandardError)
  AccessioningDisabledError = Class.new(AccessionServiceError)
  AccessionValidationFailed = Class.new(AccessionServiceError)
  NumberNotRequired = Class.new(AccessionServiceError)
  NumberNotGenerated = Class.new(AccessionServiceError)

  CENTER_NAME = 'SC' # TODO: [xxx] use confing file
  PROTECT = 'protect'
  HOLD = 'hold'
end
