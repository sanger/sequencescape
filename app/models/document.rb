class Document < ActiveRecord::Base

  # Polymorphic relationship
  belongs_to :documentable, :polymorphic => true
  
  # Creates document.db_files association so when the file is split we can get all the chunks
  has_many  :db_files, :as => :owner

  # CarrierWave uploader - gets the uploaded_data file, but saves the identifier to the "filename" column
  mount_uploader :uploaded_data, DocumentUploader, :mount_on => "filename"
  
  # Method provided for backwards compatibility
  def current_data
    uploaded_data.read
  end
  
  # Handle some of the metadata with this callback
  before_save :update_document_attributes
    
  private
    
    # Save Size/content_type Metadata
    def update_document_attributes
      if uploaded_data.present? 
        self.content_type = uploaded_data.file.content_type
        self.size    = uploaded_data.file.size        
      end
    end
end
 