Before('@enable_auditing') do
  Audit.enable_auditing
end

After('@enable_auditing') do
  Audit.disable_auditing
end