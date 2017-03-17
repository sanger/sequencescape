FactoryGirl.define do
  factory :test_download, class: SampleManifestExcel::TestDownload do
    columns {}
    validation_errors []
    no_of_rows 5
    study 'WTCCC'
    supplier 'Test Supplier'
    count 1
    type 'Tubes'
    data { { prepooled: 'No', library_type: 'My personal library type', insert_size_from: 200, insert_size_to: 1500,
                supplier_sample_name: 'SCG--1222_A0', volume: 1, concentration: 1, gender: 'Unknown', dna_source: 'Cell Line', 
                date_of_sample_collection: 'Nov-16', date_of_sample_extraction: 'Nov-16', sample_purified: 'No',
                sample_public_name: 'SCG--1222_A0', sample_taxon_id: 9606, sample_common_name: 'Homo sapiens', phenotype: 'Unknown' }.with_indifferent_access }

    initialize_with { new(data: data, columns: columns, validation_errors: validation_errors, no_of_rows: no_of_rows,
                          study: study, supplier: supplier, count: count, type: type) }
                                                      
  end
end