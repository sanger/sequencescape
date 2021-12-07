# frozen_string_literal: true

When /^I print the following labels$/ do |table|
  label_bitmaps = {}
  table.hashes.each do |h|
    field, value = %w[Field Value].map { |k| h[k] }
    label_bitmaps[field] = Regexp.new(value)
  end

  stub_request(:post, LabelPrinter::PmbClient.print_job_url).with(headers: LabelPrinter::PmbClient.headers)

  step('I press "Print labels"')

  assert_requested(
    :post,
    LabelPrinter::PmbClient.print_job_url,
    headers: LabelPrinter::PmbClient.headers,
    times: 1
  ) do |req|
    h_body = JSON.parse(req.body)
    all_label_bitmaps = h_body['data']['attributes']['labels'].first
    label_bitmaps.all? { |k, v| v.match all_label_bitmaps[k] }
  end
end

# rubocop:todo Layout/LineLength
Given /^I have a "([^"]*)" submission with (\d+) sample tubes as part of "([^"]*)" and "([^"]*)"$/ do |submission_template_name, number_of_tubes, study_name, project_name|
  # rubocop:enable Layout/LineLength
  project = FactoryBot.create :project, name: project_name
  study = FactoryBot.create :study, name: study_name
  sample_tubes = []
  1.upto(number_of_tubes.to_i) do |i|
    sample_tubes << FactoryBot.create(:sample_tube, name: "Sample Tube #{i}", barcode: i.to_s)
  end

  submission_template = SubmissionTemplate.find_by(name: submission_template_name)
  order =
    submission_template.create_with_submission!(
      study: study,
      project: project,
      user: User.last,
      assets: sample_tubes,
      request_options: {
        :multiplier => {
          '1' => '1',
          '3' => '1'
        },
        'read_length' => '76',
        'fragment_size_required_to' => '300',
        'fragment_size_required_from' => '250',
        'library_type' => 'Illumina cDNA protocol'
      }
    )
  order.submission.built!
  step('1 pending delayed jobs are processed')
end
