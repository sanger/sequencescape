# frozen_string_literal: true

# Generate a bulk submission excel template
# from basic user provided data
class BulkSubmissionExcel::DownloadsController < ApplicationController
  def new
    @submission_template = SubmissionTemplate.find_by(id: params[:submission_template_id])
    @input_field_infos = @submission_template&.input_field_infos || []
    @input_field_infos.reject! { |k| k.key == :customer_accepts_responsibility }
    render 'new', layout: !request.xhr?
  end

  def create
    finder = Asset::Finder.new(submission_parameters.fetch(:asset_barcodes, '').split(/\s+/))
    assets = finder.resolve
    bulk_submission_excel_config = BulkSubmissionExcel.configuration
    download = BulkSubmissionExcel::Download.new(
        column_list: bulk_submission_excel_config.columns.all,
        range_list: bulk_submission_excel_config.ranges,
        defaults: params[:defaults],
        assets: assets,
      )

    file = Tempfile.new
    download.save(file)
    send_file file.path,
              content_type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
              filename: build_filename(finder.barcodes)
  rescue Asset::Finder::InvalidInputException => e
    flash[:error] = e.message
    redirect_back fallback_location: bulk_submissions_path
  ensure
    file&.close
  end

  # submission_parameters is a private method used for strong parameter handling in Rails.
  # It requires the presence of :bulk_submission_excel_download in the params hash and permits only the :asset_barcodes attribute.
  # This is used to prevent mass assignment vulnerabilities when creating or updating a BulkSubmissionExcelDownload.
  # After the parameters are filtered for mass assignment, it returns the :bulk_submission_excel_download key from the params hash.
  #
  # @return [ActionController::Parameters] The permitted parameters for a BulkSubmissionExcelDownload.
  def submission_parameters
    params.require(:bulk_submission_excel_download).permit(:asset_barcodes)
    params[:bulk_submission_excel_download]
  end

  private

  # Build a filename for the file to be downloaded
  # Follows the format: first barcode_to_last barcode_date_sanger user ID
  # e.g. "SQPP-1234_to_SQPP-5678_20240521_ec20.xlsx"
  def build_filename(barcodes)
    first_barcode = barcodes.first
    last_barcode = barcodes.last
    date = Time.current.utc.strftime('%Y%m%d')
    username = current_user.login

    "#{first_barcode}_to_#{last_barcode}_#{date}_#{username}.xlsx"
  end

end
