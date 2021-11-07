class CreateValuesForms < ActiveRecord::Migration[6.1]
  def change
    create_table :values_forms do |t|
      t.references :json_form, null: false, foreign_key: true
      t.text :content_yaml
      t.string :inputs, array: true

      t.timestamps
    end
  end
end
