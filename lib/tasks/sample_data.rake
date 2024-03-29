namespace :db do
  desc "Fill database with sample data"
  task populate: :environment do
    Venue.all.destroy
    User.all.destroy
    Event.all.destroy
    Photo.all.destroy
    ScheduledEvent.all.destroy
    make_venues
    make_users
    make_existing_events
    make_photos_for_new_events
    make_scheduled_events
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

  15.times do |n|
    venue = Venue.where(:fs_venue_id => n + 2).first
    event = Event.create(:coordinates => [-74.00313913822174, 40.73359624463056],
                        :venue => Venue.where(:fs_venue_id => n).first,
                        :status => "trended",
                        :start_time => (28 + n).hours.ago.to_i,
                        :end_time => (22 + n).hours.ago.to_i,
                        :n_photos => 10,
                        :description => "",
                        :category => "concert",
                        :shortid => n,
                        )
    10.times do |m|
      photo = User.where(:ig_id => n).first.photos.create(:ig_media_id => "#{m+4670}x#{n+4430}",
                                    :url => fake_url,
                                    :time_taken => (28 + n - m).hours.ago.to_i,
                                    :coordinates => [-74.00313913822174, 40.73359624463056],
                                    :city => "newyork",
                                    :caption => "test test test 1",
                                    :venue => venue)
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
                         :venue => venue,
                         :caption => Faker::Lorem.sentence(35))
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
                         :venue => venue,
                         :caption => Faker::Lorem.sentence(35))
    end
  end
end

def make_scheduled_events
  5.times do |n|
    venue = Venue.where(:fs_venue_id => n + 18).first
    scheduled_event = venue.scheduled_events.create!( :next_start_time => ((n * 30)).minutes.ago.to_i,
                                                  :next_end_time => (90 * (n + 1)).minutes.to_i + Time.now.to_i,
                                                  :description => Faker::Lorem.sentence(6),
                                                  :category => "outdoors",
                                                  :informative_description  => Faker::Lorem.sentence(15),
                                                  :city => "newyork",
                                                  :event_layer => 3)
  end

  5.times do |n|
    venue = Venue.where(:fs_venue_id => n + 23).first
   scheduled_event = venue.scheduled_events.create!( :saturday => true,
                                                  :friday => true,
                                                  :sunday => true,
                                                  :evening => true,
                                                  :afternoon => true,
                                                  :night => true,
                                                  :description => Faker::Lorem.sentence(6),
                                                  :category => "outdoors",
                                                  :informative_description  => Faker::Lorem.sentence(15),
                                                  :city => "newyork",
                                                  :active_until => Time.now.to_i + 3.hours.to_i + n.days.to_i,
                                                  :event_layer => 1)
  end
end
