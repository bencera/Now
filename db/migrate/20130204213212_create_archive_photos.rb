class CreateArchivePhotos < ActiveRecord::Migration
  def change
    create_table :archive_photos do |t|
      t.string :mongo_id
      t.string :ig_media_id
      t.string :external_media_source
      t.string :low_resolution_url
      t.string :high_resolution_url
      t.string :thumbnail_url
      t.string :now_version
      t.text :caption
      t.integer :time_taken
      t.text :coordinates
      t.string :status
      t.string :tag
      t.string :category
      t.boolean :answered
      t.string :city
      t.string :neighborhood
      t.string :user_id
      t.text :event_ids

      t.timestamps
    end
  end
end
