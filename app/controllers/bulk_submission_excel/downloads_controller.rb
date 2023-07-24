# frozen_string_literal: true

# Generate a bulk submission excel template
# from basic user provided data
class BulkSubmissionExcel::DownloadsController < ApplicationController
  def create # rubocop:todo Metrics/AbcSize
    finder = Asset::Finder.new(submission_parameters.fetch(:asset_barcodes, '').split(/\s+/))
    download =
      BulkSubmissionExcel::Download.new(
        column_list: BulkSubmissionExcel.configuration.columns.all,
        range_list: BulkSubmissionExcel.configuration.ranges,
        defaults: params[:defaults],
        assets: finder.resolve
      )
    file = Tempfile.new
    download.save(file)
    send_file file.path,
              content_type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
              filename: "#{finder.barcodes.join('_')}_#{Time.current.strftime('%Y%m%d')}.xlsx"
  rescue Asset::Finder::InvalidInputException => e
    flash[:error] = e.message
    redirect_back fallback_location: bulk_submissions_path
  ensure
    file&.close
  end

  def new
    @submission_template = SubmissionTemplate.find_by(id: params[:submission_template_id])
    @input_field_infos = @submission_template&.input_field_infos || []
    @input_field_infos.reject! { |k| k.key == :customer_accepts_responsibility }
    render 'new', layout: !request.xhr?
  end

  def submission_parameters
    params.require(:bulk_submission_excel_download).permit(:asset_barcodes)
  end
end
