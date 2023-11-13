# frozen_string_literal: true

context 'when printing swipecard' do
  let(:barcode_printer_type) { create(:plate_barcode_printer_type) }
  let(:barcode_printer) { create(:barcode_printer, barcode_printer_type: barcode_printer_type) }
  let(:user) { create(:user) }
  let(:label_class) { LabelPrinter::Label::Swipecard }
  let(:label_template_name) { configatron.swipecard_pmb_template }
  let(:swipecard) { '53a54be5' }
  let(:print_job) do
    LabelPrinter::PrintJob.new(
      barcode_printer.name,
      label_class,
      user_login: user.login,
      swipecard: swipecard,
      label_template_name: label_template_name
    )
  end
  let(:labels_attribute) { [{ left_text: user.login, barcode: swipecard, label_name: 'main' }] }
  let(:build_attributes) do
    { printer_name: barcode_printer.name, label_template_name: label_template_name, labels: labels_attribute }
  end

  it 'builds correct attributes' do
    # This hash is sent to the printmybarcode service.
    expect(print_job.build_attributes).to eq(build_attributes)
  end

  it 'builds correct label' do
    # The hash in this array is used to populate the label template.
    expect(print_job.labels_attribute).to eq(labels_attribute)
  end

  it 'uses correct label template' do
    # This label template name should be used for printing swipecards.
    # The users controller sets it during initialisation of the print job.
    expect(print_job.label_template_name).to eq(label_template_name)
  end

  it 'uses correct printer' do
    # Printer name is used by the printmybarcode service to find the correct
    # printer type (either toshiba or squix). Because the label template name
    # is specified for the print job for swipecards, barcode printer is not
    # used to determine the label template name. The following is to make sure,
    # the specified printer name can be verified.
    expect(print_job.find_printer).to eq(barcode_printer)
  end
end
