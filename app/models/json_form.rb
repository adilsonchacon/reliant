class JsonForm < ApplicationRecord
  attr_accessor :parsed_content, :content_yaml_array

  VALID_KEY_TYPES = ['TEXT', 'INTEGER']

  VALID_VALUE_TYPES = ['TEXT', 'INTEGER', 'CHILD']

  has_many :values_form

  before_validation :parse_content
  after_validation :build_content_yaml

  validates_presence_of :content
  validate :validate_key_is_child
  validate :validate_key_true_mutable_and_has_default
  validate :validate_key_false_mutable_and_true_multiple
  validate :validate_has_key_and_value
  validate :validate_key_type
  validate :validate_value_type
  validate :validate_key_true_mutable_and_value_true_mutable

  def validate_key_is_child
    self.errors.add('content', "key type can't be child") if JsonForm.does_content_have_key_type_child?(self.parsed_content)
  end

  def validate_key_false_mutable_and_true_multiple
    self.errors.add('content', "key can't have false mutable and true multiple") if JsonForm.does_content_have_key_false_mutable_and_true_multiple?(self.parsed_content)
  end

  def validate_key_true_mutable_and_has_default
    self.errors.add('content', "key can't have true mutable and default value") if JsonForm.does_content_have_key_true_mutable_and_has_default?(self.parsed_content)
  end

  def validate_has_key_and_value
    self.errors.add('content', "does not have the key or does not have the value") if JsonForm.does_content_have_missing_key_or_value?(self.parsed_content)
  end

  def validate_key_type
    self.errors.add('content', "invalid key type") if JsonForm.does_content_have_invalid_key_type?(self.parsed_content)
  end

  def validate_value_type
    self.errors.add('content', "invalid value type") if JsonForm.does_content_have_invalid_value_type?(self.parsed_content)
  end

  def validate_key_true_mutable_and_value_true_mutable
    self.errors.add('content', "entry has key and value are mutable") if JsonForm.does_content_have_entry_key_and_value_mutable?(self.parsed_content)
  end

  def validate_children_has_at_least_one_entry
    self.errors.add('content', "children can't be empty") if JsonForm.does_content_have_empty_children?(self.parsed_content)
  end

  def parse_content
    begin
      self.parsed_content = JSON.parse(self.content)
    rescue
      self.errors.add('content', 'invalid JSON format')
      self.parsed_content = nil
    end
  end

  def build_content_yaml
    return nil if self.errors.any?

    self.content_yaml_array = JsonForm.build_content_yaml(self.parsed_content)
    add_multiple_to_content_yaml_array
    self.content_yaml = convert_content_yaml_array_to_string
  end

  def add_multiple_to_content_yaml_array
    stack_for_multiples = []
    (0..(self.content_yaml_array.length - 1)).to_a.each do |line|
      stack_for_multiples.push(line) if self.content_yaml_array[line][:multiple]
    end

    stack_for_multiples.each do |line_start|
      level = self.content_yaml_array[line_start][:level]
      last_index = self.content_yaml_array.length - 1

      multiple = [self.content_yaml_array[line_start].dup]
      multiple[0][:key] = multiple[0][:key].sub(/\_\d+\>/, '_n>') if multiple[0][:key].match(/\<[A-Za-z0-9\_\-]+\_\d+\>/)

      line_start += 1
      current_index = line_start
      (line_start..last_index).to_a.each do |line|
        current_index = line
        if level < self.content_yaml_array[line][:level]
          multiple.push(self.content_yaml_array[line].dup)
        else
          break
        end
      end
      self.content_yaml_array.insert(current_index + 1, multiple).flatten!
    end
  end

  def convert_content_yaml_array_to_string
    to_string_content = ["---"]

    self.content_yaml_array.each do |line|
      padding = line[:level] == 0 ? '' : sprintf("%#{line[:level] * 2}s", " ")
      value = line[:value].nil? ? '' : " #{line[:value]}"

      to_string_content.push("#{padding}#{line[:key]}:#{value}")
    end

    to_string_content.join("\n")
  end

  class << self
    def build_content_yaml(element, current_array = [], index = 0, level = 0, content_yaml = [])
      if element.is_a?(Array)
        build_content_yaml(element[index], element, index + 1, level, content_yaml)
      elsif element.is_a?(Hash)
        if element['key']['mutable']
          if element['value']['type'].upcase == 'CHILD'
            content_yaml.push({level: level, key: "<environment#{element['key']['multiple'] ? '_1' : '' }>", value: nil, multiple: element.dig('key', 'multiple') || false })
          else
            content_yaml.push({level: level, key: "<environment#{element['key']['multiple'] ? '_1' : '' }>", value: element['value']['default'], multiple: element.dig('key', 'multiple') || false })
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

          content_yaml.push({level: level, key: element['key']['default'], value: value, multiple: element.dig('key', 'multiple') || false })
        end

        if element.dig('value', 'type') && element['value']['type'].upcase == 'CHILD' && element['children'].present? && element['children'].is_a?(Array)
          build_content_yaml(element['children'], element['children'], 0, level + 1, content_yaml)
        else
          build_content_yaml(current_array, current_array, index, level, content_yaml)
        end
      else
        content_yaml
      end
    end

    def does_content_have_key_type_child?(element, current_array = [], index = 0, has_error = false)
      if element.is_a?(Array)
        return does_content_have_key_type_child?(element[index], element, index + 1, false)
      elsif element.is_a?(Hash)
        if element.dig('key', 'type') && element['key']['type'].upcase == 'CHILD'
          return true
        elsif element.dig('value', 'type') && element['value']['type'].upcase == 'CHILD' && element['children'].present? && element['children'].is_a?(Array)
          return does_content_have_key_type_child?(element['children'], element['children'], 0, has_error)
        else
          return does_content_have_key_type_child?(current_array, current_array, index, false)
        end
      else
        return has_error
      end
    end

    def does_content_have_key_false_mutable_and_true_multiple?(element, current_array = [], index = 0, has_error = false)
      if element.is_a?(Array)
        return does_content_have_key_false_mutable_and_true_multiple?(element[index], element, index + 1, false)
      elsif element.is_a?(Hash)
        if element.dig('key', 'multiple') && element['key']['multiple'] && !element['key']['mutable']
          return true
        elsif element.dig('value', 'type') && element['value']['type'].upcase == 'CHILD' && element['children'].present? && element['children'].is_a?(Array)
          return does_content_have_key_false_mutable_and_true_multiple?(element['children'], element['children'], 0, has_error)
        else
          return does_content_have_key_false_mutable_and_true_multiple?(current_array, current_array, index, false)
        end
      else
        return has_error
      end
    end

    def does_content_have_key_true_mutable_and_has_default?(element, current_array = [], index = 0, has_error = false)
    if element.is_a?(Array)
        return does_content_have_key_true_mutable_and_has_default?(element[index], element, index + 1, false)
      elsif element.is_a?(Hash)
        if element.dig('key', 'mutable') && element['key']['mutable'] && element['key']['default'].present?
          return true
        elsif element.dig('value', 'type') && element['value']['type'].upcase == 'CHILD' && element['children'].present? && element['children'].is_a?(Array)
          return does_content_have_key_true_mutable_and_has_default?(element['children'], element['children'], 0, has_error)
        else
          return does_content_have_key_true_mutable_and_has_default?(current_array, current_array, index, false)
        end
      else
        return has_error
      end
    end

    def does_content_have_missing_key_or_value?(element, current_array = [], index = 0, has_error = false)
      if element.is_a?(Array)
        return does_content_have_missing_key_or_value?(element[index], element, index + 1, false)
      elsif element.is_a?(Hash)
        if element['key'].nil? || element['value'].nil?
          return true
        elsif element.dig('value', 'type') && element['value']['type'].upcase == 'CHILD' && element['children'].present? && element['children'].is_a?(Array)
          return does_content_have_missing_key_or_value?(element['children'], element['children'], 0, has_error)
        else
          return does_content_have_missing_key_or_value?(current_array, current_array, index, false)
        end
      else
        return has_error
      end
    end

    def does_content_have_invalid_key_type?(element, current_array = [], index = 0, has_error = false)
      if element.is_a?(Array)
        return does_content_have_invalid_key_type?(element[index], element, index + 1, false)
      elsif element.is_a?(Hash)
        if element.dig('key', 'type') && !VALID_KEY_TYPES.include?(element['key']['type'].upcase)
          return true
        elsif element.dig('value', 'type') && element['value']['type'].upcase == 'CHILD' && element['children'].present? && element['children'].is_a?(Array)
          return does_content_have_invalid_key_type?(element['children'], element['children'], 0, has_error)
        else
          return does_content_have_invalid_key_type?(current_array, current_array, index, false)
        end
      else
        return has_error
      end
    end

    def does_content_have_invalid_value_type?(element, current_array = [], index = 0, has_error = false)
      if element.is_a?(Array)
        return does_content_have_invalid_value_type?(element[index], element, index + 1, false)
      elsif element.is_a?(Hash)
        if element.dig('value', 'type') && !VALID_VALUE_TYPES.include?(element['value']['type'].upcase)
          return true
        elsif element.dig('value', 'type') && element['value']['type'].upcase == 'CHILD' && element['children'].present? && element['children'].is_a?(Array)
          return does_content_have_invalid_value_type?(element['children'], element['children'], 0, has_error)
        else
          return does_content_have_invalid_value_type?(current_array, current_array, index, false)
        end
      else
        return has_error
      end
    end

    def does_content_have_entry_key_and_value_mutable?(element, current_array = [], index = 0, has_error = false)
      if element.is_a?(Array)
        return does_content_have_entry_key_and_value_mutable?(element[index], element, index + 1, false)
      elsif element.is_a?(Hash)
        if element.dig('key', 'mutable') && element['key']['mutable'] && element.dig('value', 'mutable') && element['value']['mutable']
          return true
        elsif element.dig('value', 'type') && element['value']['type'].upcase == 'CHILD' && element['children'].present? && element['children'].is_a?(Array)
          return does_content_have_entry_key_and_value_mutable?(element['children'], element['children'], 0, has_error)
        else
          return does_content_have_entry_key_and_value_mutable?(current_array, current_array, index, false)
        end
      else
        return has_error
      end
    end
  end
end
