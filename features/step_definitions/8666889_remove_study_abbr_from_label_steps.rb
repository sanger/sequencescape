Given /^I have a "([^"]*)" submission with (\d+) sample tubes as part of "([^"]*)" and "([^"]*)"$/ do |submission_template_name, number_of_tubes, study_name, project_name|
  project = Factory :project, :name => project_name
  study = Factory :study, :name => study_name
  sample_tubes = []
  1.upto(number_of_tubes.to_i) do |i|
    sample_tubes << Factory(:sample_tube, :name => "Sample Tube #{i}", :location => Location.find_by_name('Library creation freezer'), :barcode => "#{i}")
  end

  submission_template = SubmissionTemplate.find_by_name(submission_template_name)
  submission = submission_template.create_and_build_submission!(
    :study => study,
    :project => project,
    :workflow => Submission::Workflow.find_by_key('short_read_sequencing'),
    :user => User.last,
    :assets => sample_tubes,
    :request_options => {"multiplier"=>{"1"=>"1", "3"=>"1"}, "read_length"=>"76", "fragment_size_required_to"=>"300", "fragment_size_required_from"=>"250", "library_type"=>"Illumina cDNA protocol"}
    )
  And %Q{1 pending delayed jobs are processed}

end


Given /^the child asset of "([^"]*)" has a sanger_sample_id of "([^"]*)"$/ do |sample_tube_name, sanger_sample_id|
 sample_tube = SampleTube.find_by_name(sample_tube_name)
 Given %Q{the asset called "#{sample_tube.child.name}" has a sanger_sample_id of "#{sanger_sample_id}"}
end
