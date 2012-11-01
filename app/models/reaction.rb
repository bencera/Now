class Reaction
  include Mongoid::Document
  include Mongoid::Timestamps

  TYPE_LIKE = "like"
  TYPE_LIKE_MILESTONE = "like_milestone"
  TYPE_VIEW_MILESTONE = "view_milestone"
  TYPE_REPOST = "repost"
  TYPE_REPOST_MILESTONE = "repost_milestone"

  REPORT_LIKES_UNTIL = 5
  REPORT_REPOSTS_UNTIL = 5

  LIKE_MILESTONES = [10,25,50,100,200,500,1000]
  VIEW_MILESTONES = [100,1000,10000,100000]
  REPOST_MILESTONES = [10,25,50,100,200,500,1000]

  MILESTONE_TYPES = [TYPE_LIKE_MILESTONE, TYPE_VIEW_MILESTONE, TYPE_REPOST_MILESTONE]
  USER_REACTION_TYPES = [TYPE_LIKE, TYPE_REPOST]

  #should we instead have it belong to a reactor (facebook_user)?
  field :type
  field :message

  belongs_to :event
  belongs_to :facebook_user

  #if it's not a milestone, the reactor name is a user's name -- milestones will be different

  def self.create_reaction_and_notify(type, event, message)
    reaction = event.reactions.new
    reaction.facebook_user = event.facebook_user
    reaction.message = message
    reaction.save!
    event.notify_creator(message)
  end

end
