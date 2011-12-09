class Request
  include Mongoid::Document
  field :type
  field :question
  field :media_comment_count
  field :response
  field :nb_requests, :type => Integer, default: 0
  
  belongs_to :photo
  has_and_belongs_to_many :users
  
  #need to do validation
  
  
  def find_question(question_id, venue_name)
    question_start = ["Nice picture! ", "Hi, I have a question.. ", "Beautiful picture! " ]
    question_end = ["Thanks!", "Thank you!"]
    case question_id
      #Food questions
      when 1
        "This looks good.. What is the name of the plate?"
      when 2
        "Is it easy to get a table now at #{venue_name}?"
      when 3
        "What do you think of #{venue_name}?"
      when 4
        "What is going on now at #{venue_name}"
    end
  
  end
  
  
end