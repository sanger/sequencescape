class Document < ActiveRecord::Base
  class DbFile < ActiveRecord::Base
    set_table_name "db_files"
    belongs_to :document
    # Note: We are constrained by the database to split files into 200kbyte partitions

  end
  # This prevents the error message:
  #   "A copy of Technoweenie::AttachmentFu::ActMethods has been removed from the module tree but is still active!"
  # See http://www.pivotaltracker.com/story/show/4293575 for why this kind of works.
  # extend Technoweenie::AttachmentFu::ActMethods

  belongs_to :documentable, :polymorphic => true
  
  # Since files are stored in a separate DB table, this allows files to be split into partitions in the database
  has_many  :db_files, :class_name => "Document::DbFile"
  
  
  #CarrierWave
  mount_uploader :uploaded_data, DocumentUploader, :mount_on => "filename"
  
  def current_data
    uploaded_data.read
  end
  
   # has_attachment :storage => :multi_db_file,
   #                   :max_part_size => 200.kilobytes
   # 
  # before_validation do |record|
  #    record.filename ||= record.uploaded_data.original_filename unless record.uploaded_data.nil?
  #  end
  
 before_save :update_document_attributes
    
    private
    
    def update_document_attributes
      #TODO[JR] deal with update as well as create
      if uploaded_data.present? 
        self.content_type = uploaded_data.file.content_type
        self.size    = uploaded_data.file.size
        
      end
    end
end
 