# frozen_string_literal: true

# rubocop:todo Metrics/ModuleLength
module NavigationHelpers
  # Finds the specified page for the given model with the specified name.
  def page_for_model(model, page, name)
    object = model.find_by!(name:)
    routing_method = "#{model.name.underscore}_path"
    routing_method = "#{page}_#{routing_method}" unless page == 'show'
    send(routing_method.to_sym, object)
  end

  # Maps a static name to a static route.
  #
  # This method is *not* designed to map from a dynamic name to a
  # dynamic route like <tt>post_comments_path(post)</tt>. For dynamic
  # routes like this you should *not* rely on #path_to, but write
  # your own step definitions instead. Example:
  #
  #   Given /I am on the comments page for the "(.+)" post/ |name|
  #     post = Post.find_by_name(name)
  #     visit post_comments_path(post)
  #   end
  #
  # rubocop:disable Metrics/MethodLength
  # rubocop:disable Metrics/CyclomaticComplexity
  # rubocop:todo Metrics/PerceivedComplexity
  def path_to(page_name) # rubocop:todo Metrics/AbcSize
    case page_name
    when /the homepage/
      '/'
    when /login/
      login_path
    when /the admin page/
      admin_path
    when /the new (study|project|asset) page/, /the (study|project|asset) creation page/
      send(:"new_#{$1}_path")
    when /the (studies|projects) page/
      send(:"#{$1}_path")
    when /the custom texts admin page/
      admin_custom_texts_path
    when /the search page/
      searches_path
    when /the gel QC page/
      gels_path
    when /the sample db homepage/
      '/sdb/'
    when /the "([^"]+)" pipeline page/
      pipeline = Pipeline.find_by!(name: $1)
      pipeline_path(pipeline)
    when /the last batch show page/
      batch_path(Batch.last)
    when /the robot verification page/
      robot_verifications_path
    when /the (show|edit) page for sample "([^"]+)"/
      page_for_model(Sample, $1, $2)
    when /the (show|edit) page for project "([^"]+)"/
      page_for_model(Project, $1, $2)
    when /the (show|edit|related studies) page for study "([^"]+)"/
      page, name = $1, $2
      page_for_model(Study, page.sub(' ', '_'), name)
    when /the show accession page for study named "([^"]+)"/
      study_name = $1
      study = Study.find_by!(name: study_name)
      study_show_accession_path(study)
    when /the page for editing the last request/
      edit_request_path(Request.last!)
    when /the update page for sample "([^"]+)"/
      sample_name = $1
      sample = Sample.find_by!(name: sample_name)
      sample_path(sample)
    when /the study information page for "([^"]+)"/, /the information page for study "([^"]+)"/
      study_name = $1
      study = Study.find_by!(name: study_name)
      study_information_path(study)
    when /the study named "([^"]+)"/
      study_name = $1
      study = Study.find_by!(name: study_name)
      study_path(study)
    when /the edit page for the last batch/
      edit_batch_path(Batch.last!)
    when /the new plate page/
      new_plate_path
    when /the plate page/
      plates_path
    when /the show page for library tube "([^"]+)"/
      tube_name = $1
      library_tube = LibraryTube.find_by!(name: tube_name)
      labware_path(library_tube)
    when /^the show page for labware "([^"]+)"$/
      asset_name = $1
      asset = Labware.find_by!(name: asset_name)
      labware_path(asset)
    when /^the show page for receptacle "([^"]+)"$/
      asset_name = $1
      asset = Labware.find_by!(name: asset_name).receptacle
      receptacle_path(asset)
    when /the Submissions Inbox page/
      submissions_path
    when /the create bulk submissions page/
      '/bulk_submissions'
    when /the show page for the last submission/
      submission = Submission.last!
      submission_path(submission)
    when /the Qc reports homepage/
      study_reports_path
    when /the profile page for "([^"]+)"/
      login = $1
      user = User.find_by!(login:)
      profile_path(user)
    when /the plate purpose homepage/
      admin_plate_purposes_path
    when /the plate template homepage/
      plate_templates_path
    when /the sample logistics homepage/
      sample_logistics_path
    when /the delayed jobs admin page/
      admin_delayed_jobs_path
    when /the details page for (study) "([^"]+)"/
      page, name = $1, $2
      page_for_model(Study, 'properties', name)
    when /the asset group "([^"]+)" page for study "([^"]+)"$/
      asset_group_name, study_name = $1, $2
      study = Study.find_by!(name: study_name)
      asset_group = study.asset_groups.find_by!(name: asset_group_name)
      study_asset_group_path(study, asset_group)
    when /the show page for pipeline "([^"]+)"/
      pipeline_name = $1
      pipeline = Pipeline.find_by!(name: pipeline_name)
      pipeline_path(pipeline)

      # Add more page name => path mappings here
    when /the request page for the last request/
      request_path(Request.last!)
    when /the events page for asset with barcode "([^"]+)"/
      asset = Labware.find_from_barcode($1)
      history_labware_path(asset)
    when /the sample move using spreadsheet page/
      move_spreadsheet_samples_path
    when /the event history page for study "([^"]+)"/
      study = Study.find_by!(name: $1)
      study_events_path(study)
    when /the event history page for sample "([^"]+)"/
      sample = Sample.find_by!(name: $1)
      history_sample_path(sample)
    when /the tag changing page/
      change_tags_path
    when /the XML show page for request (\d+)/
      request = Request.find($1)
      request_path(request, format: :xml)
    when /the show page for request (\d+)/
      request = Request.find($1)
      request_path(request)
    when /^the new request page for "([^"]+)"$/
      asset = Asset.find_by!(name: $1)
      new_request_asset_path(id: asset)
    when /the faculty sponsor homepage/
      admin_faculty_sponsors_path
    when /the bait library management/
      admin_bait_libraries_path

      # Add more page name => path mappings above here
    else
      raise "Can't find mapping from \"#{page_name}\" to a path.\n" \
            'Now, go and add a mapping in features/support/paths.rb'
    end
  end
  # rubocop:enable Metrics/PerceivedComplexity, Metrics/MethodLength, Metrics/CyclomaticComplexity
end
# rubocop:enable Metrics/ModuleLength

World(NavigationHelpers)
