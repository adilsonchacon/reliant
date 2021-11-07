class ValuesForm < ApplicationRecord
  STATUS_SEEKING = 0
  STATUS_SEEK_GREATER_THAN_FOUND = 1
  STATUS_SEEK_LESS_THAN_FOUND = 2

  belongs_to :json_form

  before_validation :fill_content_yaml

  validates_presence_of :content_yaml

  private

  def fill_content_yaml
    return if self.json_form.nil?

    temp_content_yaml = self.json_form.content_yaml
    mutables = temp_content_yaml.scan(/(?<=\<)(.*?)(?=\>)/).flatten.map{ |m| "<#{m}>" }

    self.inputs.each do |input|
      temp_content_yaml = temp_content_yaml.sub(mutables[0], input)
      mutables.shift
    end

    self.content_yaml = temp_content_yaml
  end
end
