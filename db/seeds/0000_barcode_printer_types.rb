# frozen_string_literal: true

BarcodePrinterType1DTube.create(name: '1D Tube', printer_type_id: 2, label_template_name: 'sqsc_1dtube_label_template')
BarcodePrinterType96Plate.create(name: '96 Well Plate', printer_type_id: 1, label_template_name: 'sqsc_96plate_label_template')
BarcodePrinterType384Plate.create(name: '384 Well Plate', printer_type_id: 6, label_template_name: 'sqsc_384plate_label_template')
BarcodePrinterType384DoublePlate.create_with(printer_type_id: 10, label_template_name: 'plate_6mm_double_code39').find_or_create_by!(name: '384 Well Plate Double')
