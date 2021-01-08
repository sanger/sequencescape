class Search::FindRobotByBarcode < Search # rubocop:todo Style/Documentation
  def scope(criteria)
    Robot.with_barcode(criteria['barcode'])
  end
end
