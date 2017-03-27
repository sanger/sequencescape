# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2013,2015 Genome Research Ltd.

When /^I print the following labels$/ do |table|
  label_bitmaps = {}
  table.hashes.each do |h|
    field, value = ['Field', 'Value'].map { |k| h[k] }
    label_bitmaps[field] = Regexp.new(value)
  end

  stub_request(:post, LabelPrinter::PmbClient.print_job_url)
    .with(headers: LabelPrinter::PmbClient.headers)

  step('I press "Print labels"')

  assert_requested(:post, LabelPrinter::PmbClient.print_job_url,
    headers: LabelPrinter::PmbClient.headers, times: 1) do |req|
    h_body = JSON.parse(req.body)
    all_label_bitmaps = h_body['data']['attributes']['labels']['body'].first['main_label']
    label_bitmaps.all? { |k, v| v.match all_label_bitmaps[k] }
  end
end

Given /^I have a "([^"]*)" submission with (\d+) sample tubes as part of "([^"]*)" and "([^"]*)"$/ do |submission_template_name, number_of_tubes, study_name, project_name|
  project = FactoryGirl.create :project, name: project_name
  study = FactoryGirl.create :study, name: study_name
  sample_tubes = []
  1.upto(number_of_tubes.to_i) do |i|
    sample_tubes << FactoryGirl.create(:sample_tube, name: "Sample Tube #{i}", location: Location.find_by(name: 'Library creation freezer'), barcode: i.to_s)
  end

  submission_template = SubmissionTemplate.find_by(name: submission_template_name)
  submission = submission_template.create_and_build_submission!(
    study: study,
    project: project,
    workflow: Submission::Workflow.find_by(key: 'short_read_sequencing'),
    user: User.last,
    assets: sample_tubes,
    request_options: { :multiplier => { '1' => '1', '3' => '1' }, 'read_length' => '76', 'fragment_size_required_to' => '300', 'fragment_size_required_from' => '250', 'library_type' => 'Illumina cDNA protocol' }
    )
  step('1 pending delayed jobs are processed')
end

Given /^the child asset of "([^"]*)" has a sanger_sample_id of "([^"]*)"$/ do |sample_tube_name, sanger_sample_id|
 sample_tube = SampleTube.find_by(name: sample_tube_name)
 step(%Q{the asset called "#{sample_tube.child.name}" has a sanger_sample_id of "#{sanger_sample_id}"})
end
