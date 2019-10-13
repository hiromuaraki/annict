# frozen_string_literal: true

class ChangeSchema20191014 < ActiveRecord::Migration[6.0]
  def change
    enable_extension "citext"

    change_column :users, :username, :citext
    change_column :users, :email, :citext

    rename_column :episodes, :episode_records_with_body_count, :episode_record_bodies_count
  end
end
