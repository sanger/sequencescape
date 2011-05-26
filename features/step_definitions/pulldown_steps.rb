Transform /submitted to "([^\"]+)"/ do |name|
  SubmissionTemplate.find_by_name(name) or raise StandardError, "Cannot find submission template #{name.inspect}"
end

Given /^(the plate .+) has been (submitted to "[^"]+")$/ do |plate, template|
  submission = template.new_submission(
    :user            => Factory(:user),
    :study           => Factory(:study),
    :project         => Factory(:project),
    :assets          => plate.wells,
    :request_options => {
      :fragment_size_required_from => 100,
      :fragment_size_required_to   => 200,
      :read_length                 => 100
    }
  )
  submission.save!
  submission.built!

  Given 'all pending delayed jobs are processed'
end

