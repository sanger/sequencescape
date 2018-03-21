class QcFilesController < ApplicationController
  def show
    QcFile.find(params[:id]).retrieve_file do |file|
      send_file file.path, content_type: file.content_type, filename: file.filename
    end
  end

  def create
    qc_file = QcFile.new(qc_file_params)

    if qc_file.save
      redirect_to asset_path(qc_file.asset_id), notice: "#{qc_file.filename} was uploaded"
    else
      errors = qc_file.errors.full_messages.join(';').truncate(500, separator: ' ')
      redirect_to asset_path(qc_file.asset_id), alert: "#{qc_file.filename} could not be uploaded: #{errors}"
    end
  end

  private

  def qc_file_params
    params.require(:qc_file).permit(:uploaded_data, :asset_id)
  end
end
