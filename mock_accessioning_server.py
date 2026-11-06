"""
Mock ENA/EGA accessioning server for local development and testing.

Listens on http://localhost:9999 and responds to POST requests with XML receipts
that mimic the ENA/EGA submission service. Accession numbers are auto-incremented
starting from EGA000010001.

Usage:
    python mock_accessioning_server.py [--always-succeed | --always-fail]

Modes:
    (no flag)          Randomly succeed or fail each request (mix of 200/400/500/403 status codes)
    --always-succeed   Always return a success receipt (200 OK with success="true")
    --always-fail      Always return a failure receipt (randomly 200/500/403)

Examples:
    python mock_accessioning_server.py
    python mock_accessioning_server.py --always-succeed
    python mock_accessioning_server.py --always-fail

The server detects MODIFY actions in the request body and returns a modify receipt
instead of an add receipt when appropriate.
"""

import random
import sys

from http.server import BaseHTTPRequestHandler, HTTPServer
from datetime import datetime, timezone


def parse_flags():
    always_succeed = "--always-succeed" in sys.argv
    always_fail = "--always-fail" in sys.argv
    return always_succeed, always_fail


ALWAYS_SUCCEED, ALWAYS_FAIL = parse_flags()


def generate_success_response(receipt_date, accession_number):
    return f"""<?xml version="1.0" encoding="UTF-8"?>
<RECEIPT receiptDate="{receipt_date}" success="true">
  <SUBMISSION accession="SUB0000001" alias="submission_1"/>
  <STUDY accession="STD0000001"/>
  <SAMPLE accession="{accession_number}"/>
  <ACTIONS>ADD</ACTIONS>
</RECEIPT>
"""


def generate_modify_response(receipt_date, accession_number):
    return f"""
    <?xml version="1.0" encoding="UTF-8"?>
    <?xml-stylesheet type="text/xsl" href="receipt.xsl"?>
    <RECEIPT receiptDate="{receipt_date}" success="true">
        <SAMPLE accession="{accession_number}" alias="submission_1" status="PRIVATE" holdUntilDate="2028-01-08Z">
            <EXT_ID accession="SAMEA131896906" type="biosample"/>
        </SAMPLE>
        <SUBMISSION accession="" alias="submission_1-2026-01-08T14:28:09Z"/>
        <MESSAGES>
            <INFO>This submission is a TEST submission and will be discarded within 24 hours</INFO>
        </MESSAGES>
        <ACTIONS>MODIFY</ACTIONS>
        <ACTIONS>HOLD</ACTIONS>
    </RECEIPT>
    """


def generate_failure_response(receipt_date):
    return f"""<?xml version="1.0" encoding="UTF-8"?>
<RECEIPT receiptDate="{receipt_date}" success="false">
  <MESSAGES>
    <ERROR>Houston, we've had a problem.</ERROR>
    <ERROR>We've had a Main B Bus Undervolt.</ERROR>
  </MESSAGES>
</RECEIPT>
"""


class MockAccessionHandler(BaseHTTPRequestHandler):
    accession_counter = 1  # Start at 1 for EGA000010001

    def respond_with_modify(self, receipt_date, accession_number):
        modify_response = generate_modify_response(receipt_date, accession_number)
        self.send_response(200)
        self.send_header("Content-Type", "application/xml")
        self.end_headers()
        self.wfile.write(modify_response.encode("utf-8"))

    def respond_with_success(self, receipt_date, accession_number):
        # Success: 200 OK
        success_response = generate_success_response(receipt_date, accession_number)
        self.send_response(200)
        self.send_header("Content-Type", "application/xml")
        self.end_headers()
        self.wfile.write(success_response.encode("utf-8"))

    def respond_with_failure(self, receipt_date):
        failure_response = generate_failure_response(receipt_date)
        error_type = random.choice(["400", "500", "403"])
        if error_type == "400":
            self.send_response(200)
            self.send_header("Content-Type", "application/xml")
            self.end_headers()
            self.wfile.write(failure_response.encode("utf-8"))
        elif error_type == "500":
            self.send_response(500)
            self.send_header("Content-Type", "text/plain")
            self.end_headers()
            self.wfile.write(b"Internal Server Error")
        else:
            self.send_response(403)
            self.wfile.write(b"")

    def do_POST(self):
        # Log incoming request
        content_length = int(self.headers.get("Content-Length", 0))
        body = self.rfile.read(content_length) if content_length > 0 else b""
        print(f"\n--- Incoming Request ---")
        print(f"Path: {self.path}")
        print("Headers:")
        for k, v in self.headers.items():
            print(f"  {k}: {v}")
        print(f"Body:\n{body.decode('utf-8', errors='replace')}")
        print(f"-----------------------\n")

        # Get current timestamp in the required format
        now = datetime.now(timezone.utc)
        receipt_date = now.strftime("%Y-%m-%dT%H:%M:%S.%f")[:-3] + "Z"
        # Increment accession number for each request
        accession_number = f"EGA00001000{MockAccessionHandler.accession_counter}"
        MockAccessionHandler.accession_counter += 1

        if ALWAYS_SUCCEED:
            content = body.decode("utf-8", errors="replace")
            if content.find("<ACTIONS>MODIFY</ACTIONS>") != -1:
                self.respond_with_modify(receipt_date, accession_number)
            else:
                self.respond_with_success(receipt_date, accession_number)
        elif ALWAYS_FAIL:
            self.respond_with_failure(receipt_date)
        else:
            if random.choice([True, False]):
                self.respond_with_success(receipt_date, accession_number)
            else:
                self.respond_with_failure(receipt_date)


if __name__ == "__main__":
    server_address = ("", 9999)
    httpd = HTTPServer(server_address, MockAccessionHandler)
    print("Mock accession server running")
    if ALWAYS_SUCCEED:
        print("  (configured to always succeed)")
    elif ALWAYS_FAIL:
        print("  (configured to always fail)")
    print(f"Listening on http://localhost:{server_address[1]}")
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("\nShutting down")
        httpd.server_close()
