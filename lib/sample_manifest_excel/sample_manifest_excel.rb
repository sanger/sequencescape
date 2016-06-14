module SampleManifestExcel

  Hash.send(:include, CoreExtensions::Hash)
  Axlsx::Worksheet.send(:include, CoreExtensions::AxlsxWorksheet)
end