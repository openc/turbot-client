import json
import datetime

for n in range(0,20):
    data = {"number": n,
            "message": "Hello %s" % n,
            "sample_date": datetime.datetime.now().isoformat(),
            "source_url": "http://somewhere.com/%s" % n}
    # The Turbot specification simply requires us to output lines of JSON
    print json.dumps(data)
