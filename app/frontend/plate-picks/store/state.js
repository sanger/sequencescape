export default () => {
  return {
    // The main plate store. Represents the authoritative source of plate
    // information. Plates are indexed by id. Plates which have just been
    // scanned in, and thus only have barcode information, do *NOT* appear in
    // this section. This ensures this section only contains genuine plates.
    // For plates still being fetched for Sequencescape, or those which have
    // resolves with an error, see the scanStore.
    plates: {},
    // We store batches rather than picks, as the latter are a little expensive to
    // generate. This allows the server just to return a list of batches
    // associated with the plate, from which we can look up the relevant lists,
    // or fetch the batch in needed.
    batches: {},
    // Pick data is extracted from the batch payload. They get assigned ids then
    // get recorded here. This provides the authoritative source, which can be
    // used by both batches and plates. Allowing, for example, pick renaming.
    picks: {},
    // We keep track of the pick count to be able to apply a unique colour
    // to each pick. We keep it within VueX to assist with debugging and tracking.
    pickCount: 0,
    // Scan store keeps track of scanned plates. It uses the following schema:
    // { "_barcode": { barcode: barcode, id: plate_id } }
    // eg.
    // { _01234: { barcode: '01234', id: 2 }}
    // The barcode keys are prefixed with underscore to maintain insert order,
    // as purely numeric keys instead sorted in numeric order. (ES2015)
    // The id field is optional, and gets populated once the plate has been
    // fetched from Sequencescape. This ensures we can keep track of scan
    // order, and plates still awaiting the response from Sequencescape, while
    // still allowing out main plate store to be indexed by id.
    scanStore: {},
    // The options object contains any attribute that are concerned
    // with the behaviour of the app, rather than data.
    options: {
      // Controls how notifications are delivered to the user
      notifyMode: {
        // Whether to use the full pick name by default, or a short name.
        mode: "short",
      },
    },
  };
};
