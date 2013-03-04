# == Schema Information
#
# Table name: ig_relationship_entries
#
#  id               :integer         not null, primary key
#  facebook_user_id :string(255)
#  relationships    :text
#  last_refreshed   :datetime
#  cannot_load      :boolean
#  failed_loading   :boolean
#  created_at       :datetime        not null
#  updated_at       :datetime        not null
#

class IgRelationshipEntry < ActiveRecord::Base
  attr_accessible :last_refreshed, :relationships

  def do_ig_refresh
    self.last_refreshed= Time.now
    self.cannot_load = false
    self.failed_loading = false

    #dont use existing relationships for now
    begin
      ig_user = FacebookUser.find(self.facebook_user_id)
      ig_user_id = ig_user.ig_user_id

      client = InstagramWrapper.get_client(:access_token => ig_user.ig_accesstoken)

      ig_user_info = client.user_info("self")
      if ig_user_info && ig_user_info.data && ig_user_info.data.counts
        follower_count = ig_user_info.data.counts.followed_by
        follow_count = ig_user_info.data.counts.follows
        
        #if too many follows/followers, we need to log this and notify
        if follower_count > 5000 || follow_count > 5000
          self.cannot_load = true
          self.save!
          assert(false, "User id: #{self.facebook_user_id} counts are too high for personalization")
        end
      end
      
      follower_ids = []
      follower_names = {}
      followed_by_ids = []
      follow_backs = []

      relationship_hash = {}
       
      response = client.user_follows("self")

      begin 
        response.data.each do |user|
          follower_ids << user.id
          follower_names[user.id] = user.full_name.blank? ? user.username : user.full_name
          relationship_hash[user.id] ||= {:type => "follow", 
                                      :name => user.full_name.blank? ? user.username : user.full_name }
        end
      end while response && response.pagination && response.pagination.next_url && 
            (response = client.pull_pagination(response.pagination.next_url))


      response = client.user_followed_by("self")

      begin
        response.data.each do |user|
          followed_by_ids << user.id
          if follower_names[user.id]
            follow_backs << user.id 
            relationship_hash[user.id] = {:type => "follow_back", 
                                      :name => user.full_name.blank? ? user.username : user.full_name }
          end
          relationship_hash[user.id] ||= {:type => "followed_by", 
                                      :name => user.full_name.blank? ? user.username : user.full_name}
        end
      end while response && response.pagination && response.pagination.next_url && 
            (response = client.pull_pagination(response.pagination.next_url))


      follow_backs.each do |user_id|
        #ignore yourself
        next if user_id == ig_user_id

        user_info = client.user_info(user_id)
        if user_info && user_info.data && user_info.data.counts
          follower_count = user_info.data.counts.followed_by
          follow_count = user_info.data.counts.follows
          min_count = [follower_count, follow_count].min

          #we just cant deal with users where we're looking at 50 pages of users
          next if min_count > 5000

          use_followers = follower_count < follow_count
        else
          next
        end

        if use_followers
          response = client.user_followed_by(user_id)
        else
          response = client.user_follows(user_id)
        end

        begin
          response.data.each do |user|
            existing_relationship = relationship_hash[user.id]
            if existing_relationship.nil?
              relationship_hash[user.id] = {:type => "friend_of_friend", 
                                        :through => [user_id], 
                                        :through_type => [(use_followers ? "follower" : "follows")],
                                        :name => user.full_name.blank? ? user.username : user.full_name }
            elsif existing_relationship[:type] == "friend_of_friend"
              relationship_hash[user.id][:through] << user_id
              relationship_hash[user.id][:through_type] << (use_followers ? "follower" : "follows")
            end
          end
        end while response && response.pagination && response.pagination.next_url && 
              (response = client.pull_pagination(response.pagination.next_url))
      end

      self.relationships = relationship_hash.inspect

    rescue
      self.failed_loading = true
      self.save!
      raise
    end

    self.save!
  end

  def get_relationship(user_id)
    relationship_hash = eval self.relationships
  
    relationship = relationship_hash[user_id.to_s] 

    return_hash = {:type => "NONE"}

    if relationship

      return_hash[:type] = relationship[:type]

      if relationship[:type] == "follow"
        return_hash[:message] = "You follow #{relationship[:name]}"
      elsif relationship[:type] == "followed_by"
        return_hash[:message] = "#{relationship[:name]} follows you"
      elsif relationship[:type] == "follow_back"
        return_hash[:message] = "You are friends with #{relationship[:name]}"
      elsif relationship[:type] == "friend_of_friend"
        #verify relationship matters
        #put in a message

        mutual_friends = relationship[:through]

        if mutual_friends.count == 1
          return_hash[:message] = "You know #{relationship[:name]} through " + relationship_hash[relationship[:through].first][:name]
        elsif mutual_friends.count == 2
          friend_names = relationship[:through].map {|id| relationship_hash[id][:name]}.join(" and ")
          return_hash[:message] = "You know #{relationship[:name]} through #{friend_names}"
        elsif mutual_friends.count > 2
          friend_names = relationship[:through].map {|id| relationship_hash[id][:name]}
          friend_name_list = "#{friend_names[0..-2].join(", ")}, and #{friend_names.last}"
          return_hash[:message] = "You know #{relationship[:name]} through #{friend_name_list}"
        end
      end
    end

    return return_hash 

  end
end
