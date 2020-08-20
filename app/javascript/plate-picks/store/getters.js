// Getters are like computed properties
export default {
  scannedPlates: state => state.plates.filter(plate => plate.scanned),
  sortedScannedPlates: (_state, { scannedPlates }) => scannedPlates.sort((plate_a, plate_b) => plate_a.scanned - plate_b.scanned),
  scannedPlate: (_state, { scannedPlates }) => {
    return barcode => scannedPlates.some(plate => plate.barcode === barcode)
  },
  plateWithBarcode: (_state, { scannedPlates }) => {
    return barcode => scannedPlates.find(plate => plate.barcode === barcode)
  }
}
