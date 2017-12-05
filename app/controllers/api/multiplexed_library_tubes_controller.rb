# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2015 Genome Research Ltd.

class Api::MultiplexedLibraryTubesController < Api::AssetsController
  self.model_class = MultiplexedLibraryTube

  before_action :prepare_object, only: [:show, :children, :parents]
  before_action :prepare_list_context, only: [:index]

  private

  def prepare_list_context
    @context = ::MultiplexedLibraryTube.including_associations_for_json
  end
end
