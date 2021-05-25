/*
  Mock server for testing purposes
  see: https://miragejs.com
  Usage (assuming jest):
    import { startMirage } from '../_mirage_'
    let mirageServer;

    beforeEach(() => {
      mirageServer = startMirage();
    });

    afterEach(() => {
      mirageServer.shutdown();
    });
*/
import { Server, Model } from "miragejs";

export function startMirage() {
  return new Server({
    trackRequests: true,
    environment: "test",
    namespace: "plate_picks",
    models: {
      plate: Model,
      batch: Model,
    },

    routes() {
      this.get("plates/:barcode", (schema, request) => {
        return schema.plates.findBy({ barcode: request.params.barcode });
      });
      this.resource("batches");
    },
  });
}
