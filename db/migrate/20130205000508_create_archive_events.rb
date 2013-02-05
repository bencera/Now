class CreateArchiveEvents < ActiveRecord::Migration
  def change
    create_table :archive_events do |t|
      t.string :coordinates
      t.integer :start_time
      t.integer :end_time
      t.text :description
      t.string :category
      t.string :shortid
      t.string :link
      t.string :super_user
      t.string :status
      t.string :city
      t.integer :n_photos
      t.text :keywords
      t.integer :likes
      t.string :illustration
      t.boolean :featured
      t.boolean :su_renamed
      t.boolean :su_deleted
      t.boolean :reached_velocity
      t.string :ig_creator
      t.text :photo_card
      t.string :venue_fsq_id
      t.integer :n_reactions
      t.string :venue_id
      t.string :facebook_user_id
      t.text :photo_ids
      t.text :checkin_ids
      t.text :reaction_ids

      t.timestamps
    end
  end
end
