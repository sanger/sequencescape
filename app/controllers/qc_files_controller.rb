class QcFilesController < ApplicationController

  def show
    QcFile.find(params[:id]).retrieve_file do |file|
      send_file file.path, content_type: file.content_type, filename: file.filename
      
    end
  end
  
end