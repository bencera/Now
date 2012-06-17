class FacebookUser
  include Mongoid::Document
  include Mongoid::Timestamps

  field :facebook_id
  field :email
  field :now_token
  field :fb_accesstoken
  field :fb_details, type: Hash

  before_create :generate_now_token

  has_many :devices, class_name: "APN::Device"

  class << self
	def find_by_facebook_id(id)
      FacebookUser.first(conditions: { facebook_id: id })
    end

     def find_or_create_by_facebook_token(token)
      facebook_client = FacebookClient.new(token: token)

      if user = FacebookUser.find_by_facebook_id(facebook_client.user_id)
      	user.fb_accesstoken = token
      else
        user = FacebookUser.new
        user.fb_accesstoken = token
        user.facebook_id = facebook_client.user_id
        user.email = facebook_client.email
        user.fb_details = facebook_client.all_user_info
      end
      user.save!
      user
    end
end

  def generate_now_token  	
    self.now_token = Digest::SHA1.hexdigest([Time.now, rand].join)
  end


end
