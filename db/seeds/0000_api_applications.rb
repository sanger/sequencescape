  ApiApplication.new(
    :name        => 'Default Application',
    :key         => configatron.api.authorisation_code,
    :contact     => configatron.sequencescape_email,
    :description => %Q{Import of the original authorisation code and privileges to maintain compatibility while systems are migrated.},
    :privilege   => 'full'
  ).save(false)
