# Used in Generic Lims and Illumina-B Pipeline to represent MiSeq QC tube purposes.
# @see file:docs/associated_applications.md
# A MiSeq QC tube is a pool of an entire plate which is submitted to the
# MiSeq {SequencingPipeline} for QC purposes. (Largely to check representation
# of each sample within the pool)
#
# While the high throughput PCR-Free pipeline was migrated to Limber, this Purpose
# class is no longer used by any active pipelines.
#
# @deprecated Part of non-longer active pipelines, or older variants.
#             On 2019-10-01 was last used 2017-08-02 14:36:05 +0100
#
# @todo #2396 Remove this class. This will required:
#
#      - Update any purposes using this class by running `bundle exec rake remove:deprecated_purposes`
#         Ensure that this class is listed in the reported output before removing this file. You should also be safe to remove this class
#         from  lib/tasks/remove_deprecated_purposes.rake
class IlluminaC::QcPoolPurpose < Tube::Purpose
  # This class is empty and is maintained to prevent us
  # breaking existing database records until they have been
  # migrated to Tube::Purpose
end
