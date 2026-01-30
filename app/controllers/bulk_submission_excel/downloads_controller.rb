# frozen_string_literal: true

# Generate a bulk submission excel template
# from basic user provided data
class BulkSubmissionExcel::DownloadsController < ApplicationController
  CONTENT_TYPE = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'

  # Renders 'new' view with a form to download a bulk submission excel template
  # This is called when the submission template is picked from the dropdown by the user
  def new
    @submission_template = SubmissionTemplate.find_by(id: params[:submission_template_id])
    @input_field_infos = @submission_template&.input_field_infos || []
    @input_field_infos.reject! { |k| k.key == :customer_accepts_responsibility }
    render 'new', layout: !request.xhr?
  end

  def create
    download = build_download
    file = save_download_to_file(download)
    send_file_to_user(file)
  rescue Asset::Finder::InvalidInputException => e
    handle_invalid_input_exception(e)
  ensure
    file&.close
  end

  private

  # Create a download object
  def build_download
    finder = build_finder
    bulk_submission_excel_config = BulkSubmissionExcel.configuration
    BulkSubmissionExcel::Download.new(
      column_list: bulk_submission_excel_config.columns.all,
      range_list: bulk_submission_excel_config.ranges,
      defaults: params[:defaults],
      assets: finder.resolve
    )
  end

  # Build a finder to find the assets
  def build_finder
    Asset::Finder.new(submission_parameters.fetch(:asset_barcodes, '').split(/\s+/))
  end

  # Create initial temporary file to hold the download
  def save_download_to_file(download)
    file = Tempfile.new
    download.save(file)
    file
  end

  # Send the file to the user
  def send_file_to_user(file)
    finder = build_finder
    send_file file.path, content_type: CONTENT_TYPE, filename: build_filename(finder.barcodes)
  end

  # Handle invalid input exceptions by redirecting back to the bulk submissions page
  def handle_invalid_input_exception(exception)
    flash[:error] = exception.message
    redirect_back_or_to(bulk_submissions_path)
  end

  # Extract the submission parameters from the request
  def submission_parameters
    params.require(:bulk_submission_excel_download).permit(:asset_barcodes, :submission_template_id)
    params[:bulk_submission_excel_download]
  end

  # Build a filename for the file to be downloaded
  # Follows the format: first barcode_to_last barcode_date_sanger user ID
  # e.g. "SQPP-1234_to_SQPP-5678_20240521_ec20.xlsx"
  def build_filename(barcodes)
    date = Time.current.utc.strftime('%Y%m%d')
    username = current_user.login
    barcode_part = barcodes.one? ? barcodes.first.to_s : "#{barcodes.first}_to_#{barcodes.last}"

    "#{barcode_part}_#{date}_#{username}.xlsx"
  end
end
