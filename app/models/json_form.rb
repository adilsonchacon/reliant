class JsonForm < ApplicationRecord
  attr_accessor :parsed_content, :content_array

  VALID_KEY_TYPES   = ['TEXT', 'INTEGER']
  VALID_VALUE_TYPES = ['TEXT', 'INTEGER', 'CHILD']

  has_many :values_form, :dependent => :destroy

  before_validation :build_content_yaml

  validates_presence_of :content

  def generate_structure_for_html_form
    self.build_content_yaml
    self.content_array
  end

  private

  def build_content_yaml
    self.parse_content
    return nil if self.errors.any?

    self.content_array = self.compile_content_to_array(self.parsed_content)
    return nil if self.errors.any?

    self.add_multiples_to_content_array
    self.content_yaml = self.convert_content_array_to_yaml
  end

  def parse_content
    begin
      self.parsed_content = JSON.parse(self.content)
    rescue
      self.errors.add('content', 'invalid JSON format')
      self.parsed_content = nil
    end
  end

  def compile_content_to_array(element, current_array = [], index = 0, level = 0, content_array = [])
    if element.is_a?(Array)
      self.compile_content_to_array(element[index], element, index + 1, level, content_array)
    elsif element.is_a?(Hash)
      self.validate_element(element)

      content_array.push(self.transform_element_to_hash(element, level)) if !self.errors.any?

      if element.dig('value', 'type') && element['value']['type'].upcase == 'CHILD' && element['children'].present? && element['children'].is_a?(Array)
        self.compile_content_to_array(element['children'], element['children'], 0, level + 1, content_array)
      else
        self.compile_content_to_array(current_array, current_array, index, level, content_array)
      end
    else
      content_array
    end
  end

  def transform_element_to_hash(element, level)
    if element['key']['mutable']
      if element['value']['type'].upcase == 'CHILD'
        return { level: level, key: "<environment#{element['key']['multiple'] ? '_1' : '' }>", value: nil, multiple: element.dig('key', 'multiple') || false }
      else
        return { level: level, key: "<environment#{element['key']['multiple'] ? '_1' : '' }>", value: element['value']['default'], multiple: element.dig('key', 'multiple') || false }
      end
    else
      value =  if element.dig('value', 'default')
        element['value']['default']
      elsif element.dig('key', 'default')
        element['key']['default']
      else
        'value'
      end

      value = "<#{value}>" if element.dig('value', 'mutable')

      return { level: level, key: element['key']['default'], value: value, multiple: element.dig('key', 'multiple') || false }
    end
  end

  def validate_element(element)
    if element.dig('key', 'type') && element['key']['type'].upcase == 'CHILD'
      self.errors.add('content', "key type can't be child")
    end

    if element.dig('key', 'multiple') && element['key']['multiple'] && !element['key']['mutable']
      self.errors.add('content', "key can't have false mutable and true multiple")
    end

    if element.dig('key', 'mutable') && element['key']['mutable'] && element['key']['default'].present?
      self.errors.add('content', "key can't have true mutable and default value")
    end

    if element['key'].nil? || element['value'].nil?
      self.errors.add('content', "does not have the key or does not have the value")
    end

    if element.dig('key', 'type') && !VALID_KEY_TYPES.include?(element['key']['type'].upcase)
      self.errors.add('content', "invalid key type")
    end

    if element.dig('value', 'type') && !VALID_VALUE_TYPES.include?(element['value']['type'].upcase)
      self.errors.add('content', "invalid value type")
    end

    if element.dig('key', 'mutable') && element['key']['mutable'] && element.dig('value', 'mutable') && element['value']['mutable']
      self.errors.add('content', "entry has key and value are mutable")
    end
  end

  def add_multiples_to_content_array
    stack_for_multiples = []
    (0..(self.content_array.length - 1)).to_a.each do |line|
      stack_for_multiples.push(line) if self.content_array[line][:multiple]
    end

    return if stack_for_multiples.size == 0

    stack_for_multiples.each do |line_start|
      level = self.content_array[line_start][:level]
      last_index = self.content_array.length - 1

      multiple = [self.content_array[line_start].dup]
      multiple[0][:key] = multiple[0][:key].sub(/\_\d+\>/, '_n>') if multiple[0][:key].match(/\<[A-Za-z0-9\_\-]+\_\d+\>/)

      line_start += 1
      current_index = line_start
      (line_start..last_index).to_a.each do |line|
        current_index = line
        if level < self.content_array[line][:level]
          multiple.push(self.content_array[line].dup)
        else
          break
        end
      end
      self.content_array.insert(current_index + 1, multiple).flatten!
    end
  end

  def convert_content_array_to_yaml
    to_string_content = ["---"]

    self.content_array.each do |line|
      padding = line[:level] == 0 ? '' : sprintf("%#{line[:level] * 2}s", " ")
      value = line[:value].nil? ? '' : " #{line[:value]}"

      to_string_content.push("#{padding}#{line[:key]}:#{value}")
    end

    to_string_content.join("\n")
  end

end
