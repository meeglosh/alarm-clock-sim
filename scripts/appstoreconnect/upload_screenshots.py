"""Replace a screenshot set's contents with new PNGs, in order.
Usage: upload_screenshots.py <appScreenshotSetId> <png> [<png> ...]
Uploads all new screenshots first (reserve -> PUT -> commit), waits for them to
process, then deletes the old ones and sets the order, so the set is never empty.
"""
import hashlib, os, sys, time, urllib.request
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from asc_api import call

set_id, files = sys.argv[1], sys.argv[2:]
st, r = call("GET", f"/v1/appScreenshotSets/{set_id}/relationships/appScreenshots?limit=50")
assert st == 200, r
old_ids = [d["id"] for d in r["data"]]
print("old:", old_ids)

new_ids = []
for path in files:
    data = open(path, "rb").read()
    st, r = call("POST", "/v1/appScreenshots", {"data": {"type": "appScreenshots",
        "attributes": {"fileName": os.path.basename(path), "fileSize": len(data)},
        "relationships": {"appScreenshotSet": {"data": {"type": "appScreenshotSets", "id": set_id}}}}})
    assert st == 201, r
    sid = r["data"]["id"]
    for op in r["data"]["attributes"]["uploadOperations"]:
        req = urllib.request.Request(op["url"], data=data[op["offset"]:op["offset"] + op["length"]], method=op["method"])
        for h in op["requestHeaders"]:
            req.add_header(h["name"], h["value"])
        urllib.request.urlopen(req).read()
    st, r = call("PATCH", f"/v1/appScreenshots/{sid}", {"data": {"type": "appScreenshots", "id": sid,
        "attributes": {"uploaded": True, "sourceFileChecksum": hashlib.md5(data).hexdigest()}}})
    assert st == 200, r
    new_ids.append(sid)
    print("uploaded", os.path.basename(path), sid)

for _ in range(60):
    states = [call("GET", f"/v1/appScreenshots/{s}")[1]["data"]["attributes"]["assetDeliveryState"]["state"] for s in new_ids]
    if all(s == "COMPLETE" for s in states):
        break
    if any(s == "FAILED" for s in states):
        sys.exit(f"processing failed: {states}")
    time.sleep(5)
else:
    sys.exit(f"timed out: {states}")
print("processed:", states)

for s in old_ids:
    st, r = call("DELETE", f"/v1/appScreenshots/{s}")
    assert st == 204, r
st, r = call("PATCH", f"/v1/appScreenshotSets/{set_id}/relationships/appScreenshots",
             {"data": [{"type": "appScreenshots", "id": s} for s in new_ids]})
assert st == 204, r
st, r = call("GET", f"/v1/appScreenshotSets/{set_id}/appScreenshots")
print("final order:", [d["attributes"]["fileName"] for d in r["data"]])
