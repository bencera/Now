class Request
  include Mongoid::Document
  field :type
  field :question
  field :time_asked
  field :media_comment_count
  field :response
  field :time_answered  
  field :nb_requests, :type => Integer, default: 0
  
  belongs_to :photo
  has_and_belongs_to_many :users
  
  #need to do validation
  
  
  def find_question(question_id, venue_name)
    question_start = ["Hi, quick question for you.. ", "Hi, I have a question.. ", "Hi, can i ask you something? " ]
    question_end = [" Thanks!", " Thank you!"]
    case question_id
      #Food questions
      when 1
        question_middle = "This looks good.. Thinking of going to #{venue_name}. What is the name of the plate?"
      when 2
        question_middle = "Is it easy to get a table now at #{venue_name}?"
      when 3
        question_middle = "What do you think of #{venue_name}?"
      when 4
        question_middle = "What is going on now at #{venue_name}?"
      when 5
        question_middle = "What's the best item on the menu at #{venue_name}?"
      #nighlife questions
      when 10
        question_middle = "How's the crowd at #{venue_name}?"
      when 11
        question_middle = "Is it hard to get in #{venue_name}?"
      when 12
        question_middle = "Are the drinks expensive at #{venue_name}?"
      when 13
        question_middle = "How is the girl/boy ratio at #{venue_name}?"
      when 14
        question_middle = "Is there a name to drop at the entrance to get in tonight at #{venue_name}?"
      #arts and entertainment questions
      when 20
        question_middle = "What is going on now at #{venue_name}?"
      when 21
        question_middle = "What is the exhibition today at #{venue_name}?"
      when 22
        question_middle = "Is it free to enter at #{venue_name}?"
      #outdoors questions
      when 30
        question_middle = "How's the weather now around #{venue_name}?"
      when 31
        question_middle = "Is it still raining around #{venue_name}?"
      when 32
        question_middle = "What's going on at #{venue_name} now?"
    end
    
    question = question_start[rand(question_start.size)] + question_middle + question_end[rand(question_end.size)]
    question
  end
  
  
end