$(function() {
	$('.auto_search_complete').autocomplete({
    minLength: 3,
    delay: 300,
		select: function(event, ui) {
			window.location.href = 'http://0.0.0.0:3000/venues/' + ui.item.value;
		},
    source: function(request, response) {
        $.ajax({
            url: "https://api.foursquare.com/v2/venues/suggestCompletion?ll=40.745,-73.99&query=" + request.term +"&oauth_token=JBU4PLVELHYKL33FXV3Z04NNLNBJX4FZ0IT10VI4OGY5HWUG&v=20111127",
            dataType: "json",
			type: 'get',
            data: "ll=40.7,-74&query="+ request.term + "&oauth_token=JBU4PLVELHYKL33FXV3Z04NNLNBJX4FZ0IT10VI4OGY5HWUG&v=20111127&limit=5",
            success: function( data ) {
                response( $.map( data.response.minivenues, function(item){
								
						return{
								value: item.id,
								label: item.name
								
								
						}
}) );
            }
        });
    }           
});
})
