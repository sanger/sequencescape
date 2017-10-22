# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2012,2014,2015 Genome Research Ltd.

When /^I upload a file with an empty column$/ do
  upload_submission_spreadsheet('with_empty_column')
end

When /^I upload a file with a headerless columnn$/ do
  upload_submission_spreadsheet('with_headerless_column')
end

When /^I upload a file with a header at an unexpected location$/ do
  upload_submission_spreadsheet('with_moved_header')
end

When /^I upload a file with conflicting submissions$/ do
  upload_submission_spreadsheet('with_conflicting_submissions')
end
