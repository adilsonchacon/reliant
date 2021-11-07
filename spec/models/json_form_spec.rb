require 'rails_helper'

RSpec.describe JsonForm, type: :model do
  describe 'relations' do
    it { should have_many(:values_form) }
  end

  describe 'validations' do
    it { should validate_presence_of(:content) }
  end

  describe 'valid JSON inputs' do
    context 'should generate yaml with only one key-value' do
      content = File.read(File.join(Rails.root, 'spec', 'fixtures', 'valid', 'one-key-value.json')).strip
      content_yaml = File.read(File.join(Rails.root, 'spec', 'fixtures', 'valid', 'one-key-value.yaml')).strip

      let(:json_form) { create(:json_form, content: content) }

      it { expect(json_form.content_yaml).to eq(content_yaml) }
    end

    context 'should generate yaml with only one key-value and mutable key' do
      content = File.read(File.join(Rails.root, 'spec', 'fixtures', 'valid', 'one-key-value-key-mutable.json')).strip
      content_yaml = File.read(File.join(Rails.root, 'spec', 'fixtures', 'valid', 'one-key-value-key-mutable.yaml')).strip

      let(:json_form) { create(:json_form, content: content) }

      it do
        expect(json_form.content_yaml).to eq(content_yaml)
      end
    end

    context 'should generate yaml with two key-value' do
      content = File.read(File.join(Rails.root, 'spec', 'fixtures', 'valid', 'two-key-values.json')).strip
      content_yaml = File.read(File.join(Rails.root, 'spec', 'fixtures', 'valid', 'two-key-values.yaml')).strip

      let(:json_form) { create(:json_form, content: content) }

      it { expect(json_form.content_yaml).to eq(content_yaml) }
    end

    context 'should generate yaml with children' do
      content = File.read(File.join(Rails.root, 'spec', 'fixtures', 'valid', 'has-children.json')).strip
      content_yaml = File.read(File.join(Rails.root, 'spec', 'fixtures', 'valid', 'has-children.yaml')).strip

      let(:json_form) { create(:json_form, content: content) }

      it { expect(json_form.content_yaml).to eq(content_yaml) }
    end

    context 'should generate yaml with children but not multiple' do
      content = File.read(File.join(Rails.root, 'spec', 'fixtures', 'valid', 'has-children-multiple-false.json')).strip
      content_yaml = File.read(File.join(Rails.root, 'spec', 'fixtures', 'valid', 'has-children-multiple-false.yaml')).strip

      let(:json_form) { create(:json_form, content: content) }

      it { expect(json_form.content_yaml).to eq(content_yaml) }
    end
  end

  describe 'invalid JSON inputs' do
    context 'should have error "invalid value type"' do
      let(:json_form) { build :json_form, content: File.read(File.join(Rails.root, 'spec', 'fixtures', 'invalid', 'value-type.json')).strip }

      it do
        json_form.valid?
        expect(json_form.errors['content']).to include "invalid value type"
      end
    end

    context 'should have error "invalid key type"' do
      let(:json_form) { build :json_form, content: File.read(File.join(Rails.root, 'spec', 'fixtures', 'invalid', 'key-type.json')).strip }

      it do
        json_form.valid?
        expect(json_form.errors['content']).to include "invalid key type"
      end
    end

    context 'should have error "invalid JSON format"' do
      let(:json_form) { build :json_form, content: File.read(File.join(Rails.root, 'spec', 'fixtures', 'invalid', 'format.json')).strip }

      it do
        json_form.valid?
        expect(json_form.errors['content']).to include "invalid JSON format"
      end
    end

    context 'should have error "key type can\'t be child"' do
      let(:json_form) { build :json_form, content: File.read(File.join(Rails.root, 'spec', 'fixtures', 'invalid', 'key-type-is-child.json')).strip }

      it do
        json_form.valid?
        expect(json_form.errors['content']).to include "key type can't be child"
      end
    end

    context 'should have error "key can\'t have false mutable and true multiple"' do
      let(:json_form) { build :json_form, content: File.read(File.join(Rails.root, 'spec', 'fixtures', 'invalid', 'false-mutable-and-true-multiple.json')).strip }

      it do
        json_form.valid?
        expect(json_form.errors['content']).to include "key can't have false mutable and true multiple"
      end
    end

    context 'should have error "key can\'t have true mutable and default value"' do
      let(:json_form) { build(:json_form, content: File.read(File.join(Rails.root, 'spec', 'fixtures', 'invalid', 'true-mutable-and-has-default.json')).strip) }

      it do
        json_form.valid?
        expect(json_form.errors['content']).to include "key can't have true mutable and default value"
      end
    end

    context 'should have error "content has key or value entry"' do
      let(:json_form) { build :json_form, content: File.read(File.join(Rails.root, 'spec', 'fixtures', 'invalid', 'has-no-keys-and-no-values-entries.json')).strip }

      it "both does not exists" do
        json_form.valid?
        expect(json_form.errors['content']).to include "does not have the key or does not have the value"
      end
    end
  end

end
