# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2015 Genome Research Ltd.

class PacBioSequencingPipeline < Pipeline
  include Pipeline::InboxGroupedBySubmission

  self.inbox_partial = 'pac_bio_sequencing_inbox'
  ALWAYS_SHOW_RELEASE_ACTIONS = true

  self.requires_position = false

  def post_release_batch(batch, _user)
    batch.requests.each(&:transfer_aliquots)
    Messenger.create!(target: batch, template: 'PacBioRunIO', root: 'pac_bio_run')
  end
end
