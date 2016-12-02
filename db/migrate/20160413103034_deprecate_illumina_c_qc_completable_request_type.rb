# This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2016 Genome Research Ltd.
require './lib/request_class_deprecator'

class DeprecateIlluminaCQcCompletableRequestType < ActiveRecord::Migration
  include RequestClassDeprecator

  def up
    ActiveRecord::Base.transaction do
      deprecate_class('IlluminaC::Requests::QcCompleteable')
    end
  end

  def down
  end
end
