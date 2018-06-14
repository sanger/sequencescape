
class IlluminaHtp::MxTubeNoQcPurpose < IlluminaHtp::MxTubePurpose
  def mappings
    { 'cancelled' => 'cancelled', 'failed' => 'failed', 'passed' => 'passed' }
  end
  private :mappings
end
