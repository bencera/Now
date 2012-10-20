import requests

# creates an event
url = "http://localhost:3001/event/peoplecreate"
payload = {'venue_id': "4c22beee99282d7f17b667b0", 'description' : 'test', 'category' : 'outdoors', 'nowtoken': "7d4a72bfb4f71e98165a5b27de4c94d13c85c2bc",
    'photo_id_list' : "nw|distilleryimage2.s3.amazonaws.com/5653b6661ac711e2a58122000a1e87bc,ig|306180097135179015_202130604,ig|306155701949554641_10967678",  'illustration' : '306180097135179015_202130604'}


r = requests.post(url, data=payload)
print r.text
event_id = r.text.split("|")[0]

#creates a checkin
url2 =  "http://localhost:3001/checkins"
payload2 = { 'description' : 'test checkin', 'nowtoken': "7f71907348e2a84a157451d33a963d0809f9496c", 'event_id' : event_id, 
       'photo_ig_list' : "304631811941243755_187110677,304649851559351881_56156,304708600947851247_10870046" }

r = requests.post(url2, data=payload2)
print r.text


