 navigator.geolocation.getCurrentPosition(function(position) {
 window.location = 'http://www.ubimachine.com/photos?category=special&lat='+position.coords.latitude+'&lng='+position.coords.longitude;
 });