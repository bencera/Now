class CommmentInstagramController < ApplicationController
	layout nil

	def index
		client = Instagram.client(:access_token => "1200123.6c3d78e.0d51fa6ae5c54f4c99e00e85df38c435")
		photos = client.user_liked_media(options={:count => "50", :max_like_id => params[:next_max_like_id]})
		@photos = []
		@next_id = photos.pagination.next_max_like_id
		photos.data.each do |photo|
			my_comment = false
			his_answer = false
			my_answer = false
			n_comments = photo.comments.data.count
			i = 0
			photo.comments.data.each do |comment|
				if comment.from.id == "1200123"
					my_comment = true
				end
				if my_comment && comment.from.id == photo.user.id
					if comment.text.include?("@bencera") || !(comment.text.include?("@"))
						his_answer = true
					end
				end
				if my_comment && his_answer && comment.from.id == "1200123"
					my_answer = true
				end
				if my_comment && his_answer && !(my_answer) && i == n_comments -1
					@photos << photo
				end
				i = i+1
			end
		end
	end
end
