# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2011,2012,2013,2014,2015 Genome Research Ltd.

class MiSeqSequencingRequest < SequencingRequest
  include Request::CustomerResponsibility

  def flowcell_identifier
    'Cartridge barcode'
  end
end
