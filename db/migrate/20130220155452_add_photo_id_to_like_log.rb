class AddPhotoIdToLikeLog < ActiveRecord::Migration
  def change
    add_column :like_logs, :photo_id, :string
  end
end
