$(function() {
	var lls = {newyork: "40.745,-73.99", paris: "48.86,2.34", tokyo: "35.69,139.73", london: "51.51,-0.13", sanfrancisco: "37.76,-122.45"};
	$('.auto_search_complete').autocomplete({
    minLength: 3,
    delay: 100,
		select: function(event, ui) {
			window.location.href = 'http://www.ubimachine.com/venues/' + ui.item.value;
		},
    source: function(request, response) {
        $.ajax({
            url: "https://api.foursquare.com/v2/venues/suggestCompletion?ll=" + lls[window.city] + "&query=" + request.term +"&oauth_token=JBU4PLVELHYKL33FXV3Z04NNLNBJX4FZ0IT10VI4OGY5HWUG&v=20111127",
            dataType: "json",
			type: 'get',
            data: "ll=40.7,-74&query="+ request.term + "&oauth_token=JBU4PLVELHYKL33FXV3Z04NNLNBJX4FZ0IT10VI4OGY5HWUG&v=20111127&limit=5",
            success: function( data ) {
                response( $.map( data.response.minivenues, function(item){
								
						return{
								label: item.name,
								value: item.id		
						}
}) );
            }
        });
    }           
});
})