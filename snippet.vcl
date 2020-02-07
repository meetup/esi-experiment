sub vcl_recv {
    if (req.url ~ "^/esi-experiment/find/") {
        set req.url = "/esi-experiment/find.html";

        # Make sure the origin server does not gzip the
        # response. We can't process ESIs in gzipped content
        unset req.http.Accept-Encoding;
    }

    // default value for X-MEETUP-LOCATION
    declare local var.meetup_location STRING;

    if (req.topurl ~ "^/esi-experiment/find/") {
        set var.meetup_location = regsuball(req.topurl, "^/esi-experiment/find/", "");

        # Make sure the origin server does not gzip the
        # response. We can't process ESIs in gzipped content
        unset req.http.Accept-Encoding;
    }

    // for ESI subrequests to /locations/title
    // actually request location from /esi-experiment/locations/<location>.txt
    if (req.url == "/locations/title") {
        set req.url = "/esi-experiment/locations/" + var.meetup_location + ".txt";

        # Make sure the origin server does not gzip the
        # response. We can't process ESIs in gzipped content
        unset req.http.Accept-Encoding;
    }
}

sub vcl_fetch {
    if (beresp.http.Content-Type ~ "^text/html") {
        esi;
    }

    // serve custom result if location is not found (see error state below)
    if (req.url ~ "^/esi-experiment/locations/" && beresp.status == 404) {
        error 600;
    }
}

sub vcl_error {
    // produce synthetic custom response
    if (obj.status == 600) {
        set obj.status = 200;
        set obj.response = "Unknown Location";
        set obj.http.Content-Type = "text/plain";
        synthetic "unknown location";
        return(deliver);
    }
}