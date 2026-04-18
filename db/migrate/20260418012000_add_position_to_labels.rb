class AddPositionToLabels < ActiveRecord::Migration[7.0]
  def change
    add_column :labels, :position, :integer, default: 0
  end
end
