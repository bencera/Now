class AddFacebookUserIdToSentPushes < ActiveRecord::Migration
  def change
    add_column :sent_pushes, :facebook_user_id, :string
  end
end
