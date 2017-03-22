# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2014,2015 Genome Research Ltd.

module NavigationHelpers
  # Finds the specified page for the given model with the specified name.
  def page_for_model(model, page, name)
    object = model.find_by!(name: name)
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
  def path_to(page_name)
    case page_name

    when /the homepage/
     '/'
    when /login/
      login_path
    when /the admin page/
      admin_path

    when /the new (study|project|asset) page/, /the (study|project|asset) creation page/
      send(:"new_#{ $1 }_path")
    when /the (studies|projects) page/
      send(:"#{ $1 }_path")

    when /the custom texts admin page/
      admin_custom_texts_path
    when /the search page/
      searches_path
    when /the gel QC page/
      gels_path
    when /the sample db homepage/
      '/sdb/'
    when /the "([^\"]+)" pipeline page/
      pipeline = Pipeline.find_by(name: $1) or raise StandardError, "Cannot find pipeline '#{$1}'"
      pipeline_path(pipeline)

    when /the Sequenom homepage/
      sequenom_root_path
    when /the Sequenom plate page for "(DN\d+.)"/
      prefix, number, check = Barcode.split_human_barcode($1)
      sequenom_plate_path(Plate.find_by(barcode: number))
    when /Batch "(\d+)"/
      batch_path($1)
    when /the last batch show page/
      batch_path(Batch.last)
    when /the robot verification page/
      robot_verifications_path

    when /the (show|edit) page for sample "([^\"]+)"/
      page_for_model(Sample, $1, $2)

    when /the (show|edit) page for project "([^\"]+)"/
      page_for_model(Project, $1, $2)

    when /the (show|edit|related studies) page for study "([^\"]+)"/
      page, name = $1, $2
      page_for_model(Study, page.sub(' ', '_'), name)

    when /the show accession page for study named "([^\"]+)"/
      study_name = $1
      study = Study.find_by!(name: study_name)
      study_show_accession_path(study)

    when /the page for editing the last request/
      request = Request.last or raise StandardError, 'There are no requests!'
      edit_request_path(request)

    when /the update page for sample "([^\"]+)"/
      sample_name = $1
      sample      = Sample.find_by!(name: sample_name)
      sample_path(sample)

    when /the study workflow page for "([^\"]+)"/, /the workflow page for study "([^\"]+)"/
      study_name = $1
      study      = Study.find_by!(name: study_name)
      study_workflow_path(study, @current_user.workflow)

    when /the study named "([^\"]+)"/
      study_name = $1
      study      = Study.find_by!(name: study_name)
      study_path(study)

    when /the edit page for the last batch/
      batch = Batch.last!
      edit_batch_path(batch)
    when /the new plate page/
      new_plate_path
    when /the new Sequenom QC Plate page/
      new_sequenom_qc_plate_path

    when /the show page for library tube "([^\"]+)"/
      tube_name = $1
      library_tube = LibraryTube.find_by!(name: tube_name)
      asset_path(library_tube)

    when /^the show page for asset "([^\"]+)"$/
      asset_name = $1
      asset = Asset.find_by!(name: asset_name)
      asset_path(asset)

    when /^the show page for asset "([^\"]+)" within "([^\"]+)"$/
      asset_name, study_name = $1, $2
      asset = Asset.find_by(name: asset_name) or raise StandardError, "Cannot find asset #{asset_name.inspect}"
      study = Study.find_by(name: study_name) or raise StandardError, "Cannot find study #{study_name.inspect}"
      study_asset_path(study, asset)

    when /^the "([^\"]+)" workflow show page for asset "([^\"]+)" within "([^\"]+)"$/
      workflow_name, asset_name, study_name = $1, $2, $3
      asset = Asset.find_by(name: asset_name) or raise StandardError, "Cannot find asset #{asset_name.inspect}"
      study = Study.find_by(name: study_name) or raise StandardError, "Cannot find study #{study_name.inspect}"
      workflow = Submission::Workflow.find_by(name: workflow_name) or raise StandardError, "Cannot find workflow #{workflow_name.inspect}"
      study_workflow_asset_path(study, workflow, asset)

    when /^the assets page for the study "([^\"]+)"$/
      study_name = $1
      study = Study.find_by(name: study_name) or raise StandardError, "Cannot find study #{study_name.inspect}"
      study_assets_path(study)

    when /^the assets page for the study "([^\"]+)" in the "([^\"]+)" workflow$/
      study_name, workflow_name = $1, $2
      study    = Study.find_by(name: study_name) or raise StandardError, "Cannot find study #{study_name.inspect}"
      workflow = Submission::Workflow.find_by(name: workflow_name) or raise StandardError, "Cannot find workflow #{workflow_name.inspect}"
      study_workflow_assets_path(study, workflow)

    # Sample registration has a bit of an awkward flow.  'Sample registration' page is the one where people enter
    # the details of their samples, 'Sample creation' page is the same page, under a different path, and is
    # displayed if there is something wrong!  So it goes "choose how" -> "sample registration" -> "sample error".
    when /the page for choosing how to register samples for study "([^\"]+)"$/, /the sample error page for study "([^\"]+)"/
      study_name = $1
      study      = Study.find_by(name: study_name) or raise StandardError, "No study defined with name '#{study_name}'"
      study_sample_registration_index_path(study)

    when /the sample registration page for study "([^\"]+)"/
      study_name = $1
      study      = Study.find_by(name: study_name) or raise StandardError, "No study defined with name '#{study_name}'"
      new_study_sample_registration_path(study)

    when /the spreadsheet sample registration page for study "([^\"]+)"/
      study_name = $1
      study      = Study.find_by(name: study_name) or raise StandardError, "No study defined with name '#{study_name}'"
      spreadsheet_study_sample_registration_index_path(study)

    when /the sample error page for study "([^\"]+)"/
      study_name = $1
      study      = Study.find_by(name: study_name) or raise StandardError, "No study defined with name '#{study_name}'"
      study_sample_registration_index_path(study)

    when /the Submissions Inbox page/
      submissions_path
    when /the create bulk submissions page/
      '/bulk_submissions'
    when /the show page for the last submission/
      submission = Submission.last or raise StandardError, 'There are no submissions!'
      order = submission.orders.first
      # study_workflow_submission_path(order.study, order.workflow, submission)
      submission_path(submission)

    when /the submissions page for study "([^\"]+)"/
      study = Study.find_by(name: $1) or raise StandardError, "No study defined with name #{$1.inspect}"
      study_workflow_submissions_path(study, @current_user.workflow)

    when /the Qc reports homepage/
      study_reports_path

    when /the profile page for "([^"]+)"/
      login = $1
      user = User.find_by(login: login)
      profile_path(user)

    when /the plate purpose homepage/
      admin_plate_purposes_path

    when /the pico dilution index page/
      "#{pico_dilutions_path}.xml"
    when /the sequenom qc home page/
      sequenom_qc_plates_path
    when /the plate template homepage/
      plate_templates_path
    when /the sample logistics homepage/
      sample_logistics_path

    when /the delayed jobs admin page/
      url_for(controller: 'admin/delayed_jobs', action: :index)

    when /the management page for (study|project) "([^\"]+)"/
      model, model_name = $1, $2
      object = model.classify.constantize.find_by(name: model_name) or raise StandardError, "Could not find #{model} #{model_name.inspect}"
      url_for(controller: "admin/#{model.pluralize}", action: :show, id: object)

    when /the details page for (study) "([^"]+)"/
      page, name = $1, $2
      page_for_model(Study, 'properties', name)

    when /the asset group "([^"]+)" page for study "([^"]+)"$/
      asset_group_name, study_name = $1, $2
      study = Study.find_by(name: study_name) or raise StandardError, "No study defined with name '#{study_name}'"
      asset_group = study.asset_groups.find_by(name: asset_group_name) or raise StandardError, "No asset group defined with name '#{asset_group_name}'"
      study_asset_group_path(study, asset_group)

    when /the samples page for study "([^"]+)"$/
      study_name = $1
      study      = Study.find_by(name: study_name) or raise StandardError, "No study defined with name '#{study_name}'"
      study_samples_path(study)

    when /the show page for pipeline "([^"]+)"/
      pipeline_name = $1
      pipeline = Pipeline.find_by(name: pipeline_name) or raise StandardError, "No Pipeline defined with name '#{pipeline_name} '"
      pipeline_path(pipeline)

    when /the show page for batch "(\d+)"/
      batch_path($1)

    # Add more page name => path mappings here
    when /the request page for the last request/
      request = Request.last or raise StandardError, 'Cannot find the last request'
      request_path(request)

    when /the Tag Group index page/
      tag_groups_path

    when /the edit page for the first tag in "([^"]+)"/
      tag_group = TagGroup.find_by(name: $1)
      edit_tag_group_tag_path(tag_group, tag_group.tags.first)

    when /the Tag Group new page/
      new_tag_group_path

    when /the show page for tag group "([^"]+)"/
      tag_group = TagGroup.find_by(name: $1)
      tag_group_path(tag_group)

    when /the events page for asset with barcode "(\d+)"/
      asset = Asset.find_from_machine_barcode($1)
      history_asset_path(asset)

    when /the event history page for sample with sanger_sample_id "([^"]+)"/
      sample = Sample.find_by(sanger_sample_id: $1)
      history_sample_path(sample)

    when /the events page for sample "([^"]+)"/
      sample = Sample.find_by(name: $1)
      history_sample_path(sample)

    when /the sample move using spreadsheet page/
      move_spreadsheet_samples_path

    when /the event history page for study "([^"]+)"/
      study = Study.find_by(name: $1)
      study_events_path(study)
    when /the event history page for sample "([^"]+)"/
      sample = Sample.find_by(name: $1)
      history_sample_path(sample)

    when /the events page for the last sequenom plate/
      history_asset_path(SequenomQcPlate.last)

    when /the tag changing page/
      change_tags_path

    when /the new plate page/
      new_plate_path

    when /the events page for asset (\d+)/
      asset = Asset.find($1)
      history_asset_path(asset)
    when /the events page for asset "([^\"]+)"/
      asset = Asset.find_by(name: $1)
      history_asset_path(asset)

    when /the XML show page for request (\d+)/
      request = Request.find($1)
      request_path(request, format: :xml)

    when /the show page for request (\d+)/
      request = Request.find($1)
      request_path(request)

    when /^the new request page for "([^\"]+)"$/
      asset = Asset.find_by(name: $1) or raise StandardError, "Cannot find asset #{$1.inspect}"
      new_request_asset_path(id: asset)

    when /the faculty sponsor homepage/
      admin_faculty_sponsors_path
    when /the bait library management/
      admin_bait_libraries_path

    # Add more page name => path mappings above here
    else
      raise "Can't find mapping from \"#{page_name}\" to a path.\n" +
            'Now, go and add a mapping in features/support/paths.rb'
    end
  end
end

World(NavigationHelpers)
