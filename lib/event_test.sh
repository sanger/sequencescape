#!/bin/sh
export http_proxy=""
curl -H 'Content-Type:application/xml' -H 'Accept:application/xml' \
-d @test.xml http://localhost:3000/events
