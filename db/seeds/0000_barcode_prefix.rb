barcode_prefixes = ["NT", "DN", "WD", "PD", "PA", "PB", "GD", "FA", "FC", "FE", "FG", "FI", "FK", "FM", "FO", "FQ", "FS"]
barcode_prefixes.each do |prefix|
  BarcodePrefix.create!(:prefix=>prefix)
end