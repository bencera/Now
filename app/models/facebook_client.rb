class FacebookClient
	include Mongoid::Document
	field :token

	def facebook_id(token)
		get_facebook_info(token)
	end

	def user_info
    @user_info ||= get_user_info
  end

  def user_id
    user_info['id']
  end

  def all_user_info
  	user_info.parsed_response
  end

  def email
  	user_info['email']
  end

 private
  def get_user_info
		HTTParty.get("https://graph.facebook.com/me?access_token=#{self.token}")
  end

end