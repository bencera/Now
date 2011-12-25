accesstokens = [nil]
#need to do call instagram
n = 0
l = length(accesstokens)
while sum($redis.get("count:#{i}:#{accesstokens[n]}"), i) > 4500 do
  if n < l - 1
    n += 1
  else
    new_accesstokens = User.excludes(:ig_accesstoken => nil).distinct(:ig_accesstoken) #array of accesstokens
    m = 0, l_new = length(new_accesstokens)
    while accesstokens.includes?(new_accesstokens[m]) and m < (l_new - 1 ) do m += 1
    if m = l_new and accesstoken.includes?(new_accesstokens[m]
      return "sorry cant get that information now"
    else
      $redis.set("time:#{i}:#{accesstoken}") = Time.now
      [1..20].each do |i| 
        $redis.set("count:#{i}:#{accesstoken}", 0)
      end
    end
  end
end


      


#5minutes intervals

accesstokens = [nil, accesstoken1, accesstoken2, accesstoken3]

#check rate limit for these accesstoken

Instagram.call(accesstoken[n])
(Time.now - t0) / 3600
$redis.increment("count:20:#{accesstoken}")

[count:1:accesstoken1 => 20, count:2:accesstoken1 => 14, ... , count:20:accesstoken1 => 120]
last_time #end time of the last 5mins interval

if Time.now - last_time < 5minutes
  count:20:accesstoken += 1
else
  n = (Time.now - last_time) / 5minutes #integer
  last_time += n * 5minutes #change the last time
  [1..(20 - n)].each do |i|
    count:i:accesstoken = count:(i+n):accesstoken
  end
  [(20-n+1)..20].each do |i|
    count:i:accesstoken = 0
  end
  count:20:accesstoken += 1
end

  



  