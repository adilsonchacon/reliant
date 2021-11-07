require 'rails_helper'

RSpec.describe ValuesForm, type: :model do
  describe 'relations' do
    it { should belong_to(:json_form) }
  end

  describe 'validations' do
    it { should validate_presence_of(:content_yaml) }
  end

  describe 'valid inputs' do
    context 'should generate yaml with children' do
      content = File.read(File.join(Rails.root, 'spec', 'fixtures', 'valid', 'has-children.json')).strip
      content_yaml = File.read(File.join(Rails.root, 'spec', 'fixtures', 'yaml', 'has-children-form-filled.yaml')).strip

      let(:json_form) { create(:json_form, content: content) }
      let(:values_form) { create(:values_form, json_form: json_form, inputs: ['production', 'store', 'postgres', 'homologation', 'store_test', 'root']) }

      it { expect(values_form.content_yaml).to eq(content_yaml) }
    end
  end

end
