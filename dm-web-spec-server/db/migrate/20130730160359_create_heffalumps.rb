class CreateHeffalumps < ActiveRecord::Migration
  def change
    create_table :heffalumps do |t|
      t.string :color
      t.integer :num_spots
      t.boolean :striped

      t.timestamps
    end
  end
end
