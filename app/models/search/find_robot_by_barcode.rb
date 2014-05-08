class Search::FindRobotByBarcode < Search
  def scope(criteria)
    Robot.with_machine_barcode(criteria['barcode'])
  end
end
