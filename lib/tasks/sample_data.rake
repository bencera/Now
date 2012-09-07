namespace :db do
  desc "Fill database with sample data"
  task populate: :environment do
    Venue.all.destroy
    User.all.destroy
    Event.all.destroy
    Photo.all.destroy
    make_venues
    make_users
    make_existing_events
    make_photos_for_new_events
  end
end

def make_venues
  99.times do |n|
    venue = Venue.create!(:fs_venue_id => n,
                          :name => "venue_#{n}",
                          :coordinates => [-74.00313913822174, 40.73359624463056],
                          :ig_venue_id => n,
                          :address => {},
                          :city => "newyork")
  end
end

def make_users
  99.times do |n|
    user = User.new()
    user.ig_id = n
    user.save!
  end
end

def make_existing_events
  fake_url = ["http://www.google.com/images/srpr/logo3w.png",
   "http://www.google.com/images/srpr/logo3w.png",
    "http://www.google.com/images/srpr/logo3w.png"]

  #want to show events go from trending to trended, waiting to not trending
  5.times do |n|
    event = Event.create(:coordinates => [-74.00313913822174, 40.73359624463056],
                        :venue => Venue.where(:fs_venue_id => n).first,
                        :status => "trending",
                        :start_time => 16.hours.ago.to_i,
                        :end_time => 6.hours.ago.to_i,
                        :n_photos => 10,
                        :description => "",
                        :category => "concert",
                        :shortid => n,
                        )
    10.times do |m|
      photo = User.where(:ig_id => n).first.photos.create(:ig_media_id => "#{m}x#{n}",
                                    :url => fake_url,
                                    :time_taken => (16 + m).hours.ago.to_i,
                                    :coordinates => [-74.00313913822174, 40.73359624463056],
                                    :city => "newyork",
                                    :caption => "test test test 1")
      event.photos << photo
    end
  end

  5.times do |n|
    event = Event.create(:coordinates => [-74.00313913822174, 40.73359624463056],
                        :venue => Venue.where(:fs_venue_id => n + 5).first,
                        :status => "waiting",
                        :start_time => 13.hours.ago.to_i,
                        :end_time => 9.hours.ago.to_i,
                        :n_photos => 10,
                        :description => "",
                        :category => "concert",
                        :shortid => n,
                        )
    4.times do |m|
      photo = event.photos.create(:ig_media_id => "#{m+15}x#{n}",
                                    :url => fake_url,
                                    :time_taken => (13 + m).hours.ago.to_i,
                                    :coordinates => [-74.00313913822174, 40.73359624463056],
                                    :city => "newyork",
                                    :user => User.where(:ig_id => n).first,
                                    :caption => Faker::Lorem.sentence(5))
    end
  end
end


def make_photos_for_new_events

  fake_url = ["http://www.google.com/images/srpr/logo3w.png",
   "http://www.google.com/images/srpr/logo3w.png",
    "http://www.google.com/images/srpr/logo3w.png"]

  #create the impression of 5 events that should trend
  5.times do |n|
    venue = Venue.where(:fs_venue_id => n + 20).first
    10.times do |m|
      user = User.where(:ig_id => m + 20).first
      user.photos.create!(:ig_media_id => "#{m+70}x#{n}",
                         :url => fake_url,
                         :time_taken => (m * 5).minutes.ago.to_i,
                         :coordinates => [-74.00313913822174, 40.73359624463056],
                         :city => "newyork",
                         :venue => venue)
    end
  end

  #create the impression of 5 events that should not trend
  5.times do |n|
    venue = Venue.where(:fs_venue_id => n + 40).first
    3.times do |m|
      user = User.where(:ig_id => m + 40).first
      user.photos.create!(:ig_media_id => "#{m+155}x#{n}",
                         :url => fake_url,
                         :time_taken => (m * 5).minutes.ago.to_i,
                         :coordinates => [-74.00313913822174, 40.73359624463056],
                         :city => "newyork",
                         :venue => venue)
    end
  end
end
