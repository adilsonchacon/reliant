require 'rails_helper'

RSpec.describe ValuesForm, type: :model do
  describe 'relations' do
    it { should belong_to(:json_form) }
  end

  describe 'validations' do
    it { should validate_presence_of(:content_yaml) }
  end

end
