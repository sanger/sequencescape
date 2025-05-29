# frozen_string_literal: true

# Specialized sequencing pipeline for Element Aviti
class ElementAvitiSequencingPipeline < SequencingPipeline
    def post_release_batch(batch, _user)
      # Same logic as the superclass, but with a different Messenger root
      batch.assets.compact.uniq.each(&:index_aliquots)
      Messenger.create!(target: batch, template: 'FlowcellIo', root: 'eseq_flowcell')
    end
  end
  