class AddPublicEvents < ActiveRecord::Migration
  def up
    create_table :public_events do |t|
      t.references :user
      t.column :data, :json, default: {}, null: false
    end
  end

  def down
    drop_table :public_events
  end
end
