# frozen_string_literal: true

# This class used to handle the Pacbio pipelines, which have since transitioned
# to traction. This class can be removed completely once migration:
# db/migrate/20211214094820_migrate_removed_pipelines_to_legacy_class.rb
# has been run.
class PacBioSamplePrepPipeline < LegacyPipeline
end
