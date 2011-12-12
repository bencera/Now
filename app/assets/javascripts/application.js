// This is a manifest file that'll be compiled into including all the files listed below.
// Add new JavaScript/Coffee code in separate files in this directory and they'll automatically
// be included in the compiled file accessible from http://example.com/assets/application.js
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// the compiled file.
//
//= require jquery
//= require jquery_ujs
//= require_tree .

$(function() {
	$('.auto_search_complete').autocomplete({
    minLength: 1,
    delay: 300,
		select: function(event, ui) {
			alert("pierre");
		},
    source: function(request, response) {
        $.ajax({
            url: "https://api.foursquare.com/v2/venues/suggestCompletion?ll=40.745,-73.99&query=" + request.term +"&oauth_token=JBU4PLVELHYKL33FXV3Z04NNLNBJX4FZ0IT10VI4OGY5HWUG&v=20111127",
            dataType: "json",
			type: 'get',
            data: "ll=40.7,-74&query="+ request.term + "&oauth_token=JBU4PLVELHYKL33FXV3Z04NNLNBJX4FZ0IT10VI4OGY5HWUG&v=20111127",
            success: function( data ) {
                response( $.map( data.response.minivenues, function(item){
						return{
								label: item.name
						}
}) );
            }
        });
    }           
});
})

