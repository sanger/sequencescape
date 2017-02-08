# This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2011,2012 Genome Research Ltd.
# Run from Projects - read in plate barcodes from a file, create asset groups in a given project, create submissions for all asset groups in the project

# get project id
print 'Project ID? : '
project_id = gets.chomp
print 'Study ID? : '
study_id = gets.chomp
sample_name_filename = '../samplenames'

sample_names = []
myfile = File.open(sample_name_filename)
myfile.each do |line|
  line = line.chomp
  next if line.blank?
  sample_names << line
end
puts "#{sample_names.size} Sample Names read from file"

asset_group = AssetGroup.create(name: "#{project_id}_asset_group_#{Time.now}")
sample_names.each do |sample_name|
  sample = Sample.find_by(name: sample_name)
  raise "Cannot find #{sample_name}" if sample.nil?
  raise 'sample has no asset' if sample.assets.blank?
  well = sample.assets.first
  raise 'Well not found for sample' unless well.is_a?(Well)
  asset_group.assets << well
end
study = Study.find(study_id)
study.asset_groups << asset_group
study.save

assets = asset_group.assets
asset_list = []
assets.each do |asset|
  asset_list.push asset
end

project = Project.find(project_id)
submission = LinearSubmission.build(nil, study, project, Submission::Workflow.find(2), User.find_by(login: 'nts'), asset_list, [], Submission::Workflow.find(2).request_types.map { |r| r.id }, [], [])
