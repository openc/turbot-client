import json

for n in range(0,20):
    data = {"number": n, "message": "Hello %s" % n}
    print json.dumps(data)
