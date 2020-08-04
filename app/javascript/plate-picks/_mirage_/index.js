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
import { Server, Model } from "miragejs"

export function startMirage() {
  return new Server({
    environment: 'test',
    models: {
      plates: Model,
      batches: Model,
    },

    routes() {
      this.get("plates/:barcode")
      this.resource("batches")
    },
  })
}
