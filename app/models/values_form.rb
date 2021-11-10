class ValuesForm < ApplicationRecord
  STATUS_SEEKING = 0
  STATUS_SEEK_GREATER_THAN_FOUND = 1
  STATUS_SEEK_LESS_THAN_FOUND = 2

  belongs_to :json_form

  before_validation :fill_content_yaml

  validates_presence_of :content_yaml
  validate :validate_inputs

  private

  def validate_inputs
    return if self.inputs.nil?

    self.inputs.each do |input|
      if input == ""
        self.errors.add('inputs', 'has at least one empty string')
        break
      end
    end
  end

  def fill_content_yaml
    return if self.json_form.nil? || self.json_form.content_yaml.nil?

    temp_content_yaml = self.json_form.content_yaml
    mutables = temp_content_yaml.scan(/(?<=\<)(.*?)(?=\>)/).flatten.map{ |m| "<#{m}>" }

    self.inputs.each do |input|
      temp_content_yaml = temp_content_yaml.sub(mutables[0], input)
      mutables.shift
    end

    self.content_yaml = temp_content_yaml
  end
end
