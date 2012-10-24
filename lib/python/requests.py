import requests
import random

# creates an event
url = "http://localhost:3001/event/peoplecreate"
url2 = "http://now-testing.herokuapp.com/event/peoplecreate"

payload = {'venue_id': "4b68c5b0f964a5201f8c2be3", 'description' : 'cheering for the aggies', 'category' : 'sport', 'nowtoken': "7f71907348e2a84a157451d33a963d0809f9496c", 'photo_id_list' :"nw|distilleryimage5.s3.amazonaws.com/ad0231281ada11e2bacf1231381b7928,ig|306461983332608997_27488305,ig|306461851103923195_237819225,ig|306451406061169626_20203193,ig|306450448023415759_20203193",  'illustration' : '306461983332608997_27488305'}

payload2 =  {'venue_id': "4b68c5b0f964a5201f8c2be3", 'description' : 'test', 'category' : 'sport', 'nowtoken' : "b6721f53afe81a87b637aa2699ee82c3161d55d0", 'photo_id_list' :"nw|distilleryimage5.s3.amazonaws.com/ad0231281ada11e2bacf1231381b7928,ig|306461983332608997_27488305,ig|306461851103923195_237819225,ig|306451406061169626_20203193,ig|306450448023415759_20203193",  'illustration' : '306461983332608997_27488305'}

payload3 = {'venue_id': '40f5c900f964a520a00a1fe3', 'photo_id_list' :"ig|309317065007354995_24298764,ig|309286989138964199_35089554,ig|309247383265320742_5309070", 'description' : 'test', 'category' : 'sport', 'nowtoken' : "d789dfe1d55150406eefae8ad088bb0a591c3348",   'illustration' : '309317065007354995_24298764'}

r = requests.post(url2, data=payload3)
print r.text
event_id = r.text.split("|")[0]

#creates a checkin
url2 =  "http://localhost:3001/checkins"
payload2 = { 'description' : 'test checkin', 'nowtoken': "7f71907348e2a84a157451d33a963d0809f9496c", 'event_id' : event_id, 
       'photo_ig_list' : "304631811941243755_187110677,304649851559351881_56156,304708600947851247_10870046" }

r = requests.post(url2, data=payload2)
print r.text


  

