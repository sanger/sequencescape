# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2015, 2016 Genome Research Ltd.

class ProductCatalogue::LibraryDriven

  attr_reader :product

  def initialize(catalogue, submission_attributes)
    # library_type_name will be set to nil if it was not defined
    # We can't use fetch here, as in some cases submission_attributes[:request_options] is nil
    # rather than just undefined.
    library_type_name = (submission_attributes[:request_options] || {})[:library_type]
    @product = catalogue.product_with_default(library_type_name)
  end

end
