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
  # TODO: validate :validate_key_true_mutable_and_value_true_mutable

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
    pp self.content_yaml_array
    pp '- - - - - - - - - ' * 4
    # if level is 0 then  => ""
    # sprintf("%2s", " ") => "  "
    # sprintf("%4s", " ") => "    "
    # sprintf("%6s", " ") => "      "
    # sprintf("%8s", " ") => "        "
    # ...
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
          content_yaml.push({level: level, key: element['key']['default'], value: (element.dig('value', 'mutable') ? '<value>' : element['value']['default']), multiple: element.dig('key', 'multiple') || false })
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
  end

end
