class MainDistributor
  
  @queue = :main_distributor

  def self.perform(in_params="{}")
    params = eval in_params
    
    queue_time = Time.now.to_i

    #find all users awaiting a feed pull.  
    #this logic can be made more sophisticated to load balance but for now, just pull everyone not recently or waiting to be processed
    
    users = FacebookUser.where(:last_ig_update.lt => 15.minutes.ago.to_i, :last_ig_queue.lt => 15.minutes.ago.to_i, :ig_accesstoken.ne => nil, "now_profile.personalize_ig_feed" => true).entries.shuffle 

    user_groups = [[]]

    users.each do |user|
      user_groups.last << user
      user_groups << [] if user_groups.last.count >= 20
    end

    user_groups.each do |user_group|
      user_id_list = user_group.map{|user| user.now_id}
      user_group.each {|user| user.last_ig_queue = queue_time; user.save!}
      Resque.enqueue(UserFollow3, {:user_ids => user_id_list})
    end
  end
end
