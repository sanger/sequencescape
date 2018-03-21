# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2015 Genome Research Ltd.

class Api::AssetsController < Api::BaseController
  def children
    respond_to do |format|
      format.json { render json: @object.children.map(&:list_json) }
    end
  end

  def parents
    respond_to do |format|
      format.json { render json: @object.parents.map(&:list_json) }
    end
  end
end
