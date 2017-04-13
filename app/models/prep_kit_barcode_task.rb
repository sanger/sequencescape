# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2015 Genome Research Ltd.

class PrepKitBarcodeTask < Task
  class PrepKitBarcodeData < Task::RenderElement
    def initialize(request)
      super(request)
    end
  end

  def create_render_element(request)
    request.asset && PrepKitBarcodeData.new(request)
  end

  def partial
    'prep_kit_barcode_batches'
  end

  def render_task(workflow, params)
    super
    workflow.render_prep_kit_barcode_task(self, params)
  end

  def included_for_render_task
    [:pipeline]
  end

  def included_for_do_task
    [:pipeline, { requests: :target_asset }]
  end

  def do_task(workflow, params)
    workflow.do_prep_kit_barcode_task(self, params)
  end
end
