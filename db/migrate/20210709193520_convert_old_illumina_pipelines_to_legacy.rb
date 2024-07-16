# frozen_string_literal: true

# We don't completely destroy old pipelines, but convert them to Legacy to allow
# us to strip out the old code.
class ConvertOldIlluminaPipelinesToLegacy < ActiveRecord::Migration[5.2]
  def up
    Pipeline.where(sti_type: %w[MultiplexedLibraryCreationPipeline LibraryCreationPipeline]).update_all(
      sti_type: 'LegacyPipeline'
    )
  end

  def down
    raise ActiveRecord::IrreversibleMigration unless ENV['NO_REALLY'] == 'true'

    # The following code makes assumptions about names, and mimic the production
    # state when the migration was written.
    Pipeline.transaction do
      Pipeline.where(name: ['Illumina-B MX Library Preparation', 'Illumina-C MX Library Preparation']).update_all(
        sti_type: 'MultiplexedLibraryCreationPipeline'
      )
      Pipeline.where(name: ['Illumina-C Library preparation']).update_all(sti_type: 'LibraryCreationPipeline')
    end
  end
end
