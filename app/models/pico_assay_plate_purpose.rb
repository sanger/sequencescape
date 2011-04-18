class PicoAssayPlatePurpose < PlatePurpose

  def child_plate_purposes
    pico_assay_a = PlatePurpose.find_by_name("Pico Assay A")
    pico_assay_b = PlatePurpose.find_by_name("Pico Assay B")
    [pico_assay_a, pico_assay_b]
  end
end
