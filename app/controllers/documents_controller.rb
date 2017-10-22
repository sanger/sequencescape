# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2014,2015 Genome Research Ltd.

class DocumentsController < ApplicationController
  def show
    @document = Document.find(params[:id])
    send_data @document.current_data, filename: @document.filename, type: @document.content_type, disposition: 'inline'
  end
end
