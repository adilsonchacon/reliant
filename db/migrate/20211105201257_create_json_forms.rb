class CreateJsonForms < ActiveRecord::Migration[6.1]
  def change
    create_table :json_forms do |t|
      t.text :content
      t.text :content_yaml

      t.timestamps
    end
  end
end
