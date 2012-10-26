import requests
import random

# creates an event
url = "http://localhost:3001/event/peoplecreate"
url2 = "http://now-uat.herokuapp.com/event/peoplecreate"

local_token = "7d4a72bfb4f71e98165a5b27de4c94d13c85c2bc"
production_token = "b6721f53afe81a87b637aa2699ee82c3161d55d0"

payload = {'venue_id': "4b68c5b0f964a5201f8c2be3", 'description' : 'cheering for the aggies', 'category' : 'sport', 'nowtoken': "7f71907348e2a84a157451d33a963d0809f9496c", 'photo_id_list' :"nw|distilleryimage5.s3.amazonaws.com/ad0231281ada11e2bacf1231381b7928,ig|306461983332608997_27488305,ig|306461851103923195_237819225,ig|306451406061169626_20203193,ig|306450448023415759_20203193",  'illustration' : '306461983332608997_27488305'}

payload2 =  {'venue_id': "4b68c5b0f964a5201f8c2be3", 'description' : 'test', 'category' : 'sport', 'nowtoken' : "b6721f53afe81a87b637aa2699ee82c3161d55d0", 'photo_id_list' :"nw|distilleryimage5.s3.amazonaws.com/ad0231281ada11e2bacf1231381b7928,ig|306461983332608997_27488305,ig|306461851103923195_237819225,ig|306451406061169626_20203193,ig|306450448023415759_20203193",  'illustration' : '306461983332608997_27488305'}

payload3 = {'venue_id': '4c1c2e25b9f876b07e977b46', 'photo_id_list' :"ig|310719761157998786_214535273,ig|310718932497746107_214535273,ig|310703504734939857_10278193,ig|310698685090726270_20260223,ig|310666498599396457_36682152,ig|310614476066817381_173930928",   'illustration' : '310719761157998786_214535273'}

payload3['nowtoken'] = production_token 

r = requests.post(url2, data=payload3)
print r.text
event_id = r.text.split("|")[0]

#creates a checkin
url2 =  "http://localhost:3001/checkins"
payload2 = { 'description' : 'test checkin', 'nowtoken': "7f71907348e2a84a157451d33a963d0809f9496c", 'event_id' : event_id, 
       'photo_ig_list' : "304631811941243755_187110677,304649851559351881_56156,304708600947851247_10870046" }

r = requests.post(url2, data=payload2)
print r.text


  

