import requests

# creates an event
url = "http://localhost:3001/event/peoplecreate"
payload = {'venue_id': "4c22beee99282d7f17b667b0", 'description' : 'test', 'category' : 'outdoors', 'nowtoken': "7f71907348e2a84a157451d33a963d0809f9496c",
    'photo_ig_list' : "304551376466017109_5136853,304565872418631112_27908594,304578840375572942_11733053", 'illustration' : '304551376466017109_5136853'}

r = requests.post(url, data=payload)
print r.text
event_id = r.text.split("|")[0]

#creates a checkin
url2 =  "http://localhost:3001/checkins"
payload2 = { 'description' : 'test checkin', 'nowtoken': "7f71907348e2a84a157451d33a963d0809f9496c", 'event_id' : event_id, 
       'photo_ig_list' : "304631811941243755_187110677,304649851559351881_56156,304708600947851247_10870046" }

r = requests.post(url2, data=payload2)
print r.text


