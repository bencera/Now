# == Schema Information
#
# Table name: archive_photos
#
#  id                    :integer         not null, primary key
#  mongo_id              :string(255)
#  ig_media_id           :string(255)
#  external_media_source :string(255)
#  low_resolution_url    :string(255)
#  high_resolution_url   :string(255)
#  thumbnail_url         :string(255)
#  now_version           :string(255)
#  caption               :text
#  time_taken            :integer
#  coordinates           :text
#  status                :string(255)
#  tag                   :string(255)
#  category              :string(255)
#  answered              :boolean
#  city                  :string(255)
#  neighborhood          :string(255)
#  user_id               :string(255)
#  event_ids             :text
#  created_at            :datetime        not null
#  updated_at            :datetime        not null
#

class ArchivePhoto < ActiveRecord::Base
  attr_accessible :answered, :caption, :category, :city, :coordinates, :event_ids, :external_media_source, :high_resolution_url, :ig_media_id, :low_resolution_url, :mongo_id, :neighborhood, :now_version, :status, :tag, :thumbnail_url, :time_taken, :user_id

  serialize :event_ids
  serialize :coordinates

  def set_event_ids(event_id_array)
    self.event_ids = event_id_array.map {|event_id| event_id.to_s}.join(",")
  end

  def get_event_ids()
    self.event_ids.split(",")
  end

  def set_coordinates(coordinates_array)
    self.coordinates = coordinates_array.join(",")
  end

  def get_coordinates()
    self.coordinates.split(",").map{|x| x.to_f}
  end
end
