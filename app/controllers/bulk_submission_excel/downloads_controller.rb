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
    bulk_submission_excel_config = BulkSubmissionExcel.configuration
    download = BulkSubmissionExcel::Download.new(
        column_list: bulk_submission_excel_config.columns.all,
        range_list: bulk_submission_excel_config.ranges,
        defaults: params[:defaults],
        assets: finder.resolve
      )

    file = Tempfile.new
    download.save(file)
    send_file file.path,
              content_type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
              filename: build_filename
  rescue Asset::Finder::InvalidInputException => e
    flash[:error] = e.message
    redirect_back fallback_location: bulk_submissions_path
  ensure
    file&.close
  end

  def submission_parameters
    params.require(:bulk_submission_excel_download).permit(:asset_barcodes)
  end

  private

  # Build a filename for the file to be downloaded
  # Consists of the template name in kebab-case, followed by the current date and time in ISO8601 format
  # e.g. "submission-template_20190101T120000.xlsx"
  def build_filename
    template_name = params[:defaults].fetch(:template_name, 'Submission Template')
    # convert to kebab-case, catching existing hyphens
    template_name = template_name.downcase.gsub(/[-\s]+/, '-')
    "#{template_name.dasherize}_#{Time.current.strftime('%Y%m%dT%H%M%S')}.xlsx"
  end

end
