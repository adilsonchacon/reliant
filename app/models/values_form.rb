class ValuesForm < ApplicationRecord
  belongs_to :json_form

  validates_presence_of :content_yaml
end
