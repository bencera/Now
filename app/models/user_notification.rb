class UserNotification
  include Mongoid::Document
  include Mongoid::Timestamps

  field :notifications, :type => Array, :default => []
  field :new_notifications, :type => Integer, :default => 0

  embedded_in  :facebook_user

  def add_notification(sent_push, options={})
    sp = sent_push.to_reaction(options)

    while self.notifications.count >= 20
      self.notifications.pop
    end
    
    self.notifications.unshift(sp)
    self.new_notifications += 1

    self.save!
  end

  def get_notifications
    self.new_notifications = 0
    self.save
    #debug
    #
    #self.notifications.map{|notification| OpenStruct.new(eval notification)}

#    self.notifications.map{|notification| x = eval notification; x[:reactor_photo_url] = "http://images.instagram.com/profiles/profile_618031_75sq_1363255067.jpg"; x[:reactor_name] = "Some Bitch"; x[:reaction_type] = [ "friend", "world", "local", "comment"].sample; OpenStruct.new(x)}
    
    [OpenStruct.new({
    fake: true,
    reaction_type: "comment",
    reactor_name: "Seiji Carpenter",
    reactor_photo_url: "http://images.instagram.com/profiles/profile_618031_75sq_1363255067.jpg",
    venue_name: "",
    counter: 0,
    reactor_id: "0",
    event_id: "515864e6a683a30038000012",
    timestamp: 1364766858,
    message: "Seiji Carpenter says \"It's crowded here!\""
    }),

    OpenStruct.new({
    fake: true,
    reaction_type: "local",
    reactor_name: "Some Bitch",
    reactor_photo_url: "http://images.instagram.com/profiles/profile_618031_75sq_1363255067.jpg",
    venue_name: "",
    counter: 0,
    reactor_id: "0",
    event_id: "5158927b682013009200000f",
    timestamp: 1364764228,
    message: "\u{1F378} Drinking like a mofo @ Max Fish"
    }),

    OpenStruct.new({
    fake: true,
    reaction_type: "friend",
    reactor_name: "Some Bitch",
    reactor_photo_url: "http://images.instagram.com/profiles/profile_618031_75sq_1363255067.jpg",
    venue_name: "",
    counter: 0,
    reactor_id: "0",
    event_id: "51586aef4721da2b46000016",
    timestamp: 1364759352,
    message: "Seiji Carpenter is at NYC Bhangra Holi Hai. Very High Activity"
    }),

    OpenStruct.new({
    fake: true,
    reaction_type: "world",
    reactor_name: "Some Bitch",
    reactor_photo_url: "http://images.instagram.com/profiles/profile_618031_75sq_1363255067.jpg",
    venue_name: "",
    counter: 0,
    reactor_id: "0",
    event_id: "51570f529b1ef70068000010",
    timestamp: 1364697261,
    message: "See the pope's last audience"
    })]

    
  end

end
