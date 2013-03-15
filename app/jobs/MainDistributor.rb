class MainDistributor
  
  @queue = :main_distributor

  def self.perform(in_params="{}")
    params = eval in_params
    
    queue_time = Time.now.to_i

    #find all users awaiting a feed pull.  
    #this logic can be made more sophisticated to load balance but for now, just pull everyone not recently or waiting to be processed
    
    users_query = FacebookUser.where(:last_ig_update.lt => 30.minutes.ago.to_i, "$or" => [{"last_ig_queue" => nil}, {"last_ig_queue" => {"$lt" => 30.minutes.ago.to_i}}], :ig_accesstoken.ne => nil, "now_profile.personalize_ig_feed" => true)

    users = users_query.entries.shuffle ; puts ""

    #this might not be the best idea -- if this crashes, those users wont get an update for 15 more minutes
    #probably wrap the rest of this in a begin...rescue and we can unset it

    users_query.update_all(:last_ig_queue => queue_time) 

    user_groups = [[]]

    users.each do |user|
      user_groups.last << user
      user_groups << [] if user_groups.last.count >= 20
    end; puts ""

    #enque a max of 5 groups each cycle -- gotta limit this somehow
    user_groups[0..5].each do |user_group|
      user_id_list = user_group.map{|user| user.now_id}
      Resque.enqueue(UserFollow3, {:user_id_list => user_id_list}.inspect)
    end
  end
end
