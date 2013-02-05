# == Schema Information
#
# Table name: archive_events
#
#  id               :integer         not null, primary key
#  coordinates      :string(255)
#  start_time       :integer
#  end_time         :integer
#  description      :text
#  category         :string(255)
#  shortid          :string(255)
#  link             :string(255)
#  super_user       :string(255)
#  status           :string(255)
#  city             :string(255)
#  n_photos         :integer
#  keywords         :text
#  likes            :integer
#  illustration     :string(255)
#  featured         :boolean
#  su_renamed       :boolean
#  su_deleted       :boolean
#  reached_velocity :boolean
#  ig_creator       :string(255)
#  photo_card       :text
#  venue_fsq_id     :string(255)
#  n_reactions      :integer
#  venue_id         :string(255)
#  facebook_user_id :string(255)
#  photo_ids        :text
#  checkin_ids      :text
#  reaction_ids     :text
#  created_at       :datetime        not null
#  updated_at       :datetime        not null
#

class ArchiveEvent < ActiveRecord::Base
  attr_accessible :category, :checkin_ids, :city, :coordinates, :description, :end_time, :facebook_user_id, :featured, :ig_creator, :illustration, :keywords, :likes, :link, :n_photos, :n_reactions, :photo_card, :photo_ids, :reached_velocity, :reaction_ids, :shortid, :start_time, :status, :su_deleted, :su_renamed, :super_user, :venue_fsq_id, :venue_id

  def get_checkin_ids
    self.checkin_ids.split(",")
  end

  def set_checkin_ids(checkin_id_array)
    self.checkin_ids = checkin_id_array.map {|x| x.to_s}.join(",")
  end

  def get_coordinates
    self.coordinates.split(",").map {|x| x.to_f}
  end

  def set_coordinates(coordinates_array)
    self.coordinates = coordinates_array.join(",")
  end

  def set_keywords(keyword_array)
    #keywords cant have a comma in them
    self.keywords = keywords.join(",")
  end

  def get_keywords()
    self.keywords.split(",")
  end

  def set_photo_card(photo_card_array)
    self.photo_card = photo_card_array.map{|x| x.to_s}.join(",")
  end

  def get_photo_card
    self.photo_card.split(",")
  end

  def set_photo_ids(photo_ids_array)
    self.photo_ids = photo_ids_array.map{|x| x.to_s}.join(",")
  end

  def get_photo_ids
    self.photo_ids.split(",")
  end

  def set_reaction_id(reaction_id_array)
    self.reaction_ids = reaction_id_array.map{|x| x.to_s}.join(",")
  end

  def get_reaction_ids
    self.reaction_ids.split(",")
  end

end
