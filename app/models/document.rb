class Document < ActiveRecord::Base
  # This prevents the error message:
  #   "A copy of Technoweenie::AttachmentFu::ActMethods has been removed from the module tree but is still active!"
  # See http://www.pivotaltracker.com/story/show/4293575 for why this kind of works.
  extend Technoweenie::AttachmentFu::ActMethods

  belongs_to :documentable, :polymorphic => true

  has_attachment :storage => :multi_db_file,
                 :max_part_size => 200.kilobytes

  before_validation do |record|
    record.filename ||= record.uploaded_data.original_filename unless record.uploaded_data.nil?
  end
end
