#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2015 Genome Research Ltd.

##
# A messenger creator acts as a message factory for a given
# for a given plate. They are currently triggered by:
# 1. Cherrypick batch release
# They specify both a template (under Api::Messages) and a root
class MessengerCreator < ActiveRecord::Base

  belongs_to :purpose
  validates_presence_of :purpose, :root, :template

  validate :template_exists?

  def create!(target)
    Messenger.create!(:target=>target, :root=>root, :template=>template)
  end

  private

  def template_exists?
    true
  end

end
