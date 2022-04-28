# frozen_string_literal: true
class QcFilesController < ApplicationController # rubocop:todo Style/Documentation
  def show
    QcFile
      .find(params[:id])
      .retrieve_file { |file| send_file file.path, content_type: file.content_type, filename: file.filename }
  end

  def create
    qc_file = QcFile.new(qc_file_params)

    if qc_file.save
      redirect_to labware_path(qc_file.asset_id), notice: "#{qc_file.filename} was uploaded"
    else
      errors = qc_file.errors.full_messages.join(';').truncate(500, separator: ' ')
      redirect_to labware_path(qc_file.asset_id), alert: "#{qc_file.filename} could not be uploaded: #{errors}"
    end
  end

  private

  def qc_file_params
    params.require(:qc_file).permit(:uploaded_data, :asset_id)
  end
end
