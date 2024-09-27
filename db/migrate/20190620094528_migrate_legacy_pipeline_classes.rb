# frozen_string_literal: true

# THese pipelines have been using classes which inherit from
# LegacyPipeline for a while. This lets us remove those classes
class MigrateLegacyPipelineClasses < ActiveRecord::Migration[5.1]
  def up
    Pipeline.where(
      sti_type: %w[
        DnaQcPipeline
        PulldownLibraryCreationPipeline
        PulldownMultiplexLibraryPreparationPipeline
        QcPipeline
        StripTubeCreationPipeline
        UnrepeatableSequencingPipeline
      ]
    ).update_all(sti_type: 'LegacyPipeline')
  end

  def down
    raise ActiveRecord::IrreversibleMigration unless ENV['NO_REALLY'] == 'true'

    # The following code makes assumptions about names, and mimic the production
    # state when the migration was written.
    [
      ['Manual Quality Control', 'QcPipeline'],
      ['Quality Control', 'QcPipeline'],
      ['DNA QC', 'DnaQcPipeline'],
      ['Pulldown library preparation', 'PulldownLibraryCreationPipeline'],
      ['Pulldown Multiplex Library Preparation', 'PulldownMultiplexLibraryPreparationPipeline'],
      ['Strip Tube Creation', 'StripTubeCreationPipeline'],
      ['HiSeq X PE (spiked in controls) from strip-tubes', 'UnrepeatableSequencingPipeline']
    ].each do |name, sti_type|
      pipeline = Pipeline.find_by(name:)
      next if pipeline.nil?

      pipeline.update!(sti_type:)
    end
  end
end
