# frozen_string_literal: true

RSpec.describe StatusAssignable do
  around do |example|
    described_class.clear_dictionary
    example.run
    described_class.clear_dictionary
  end

  describe '.status_dictionary' do
    it 'returns the default statuses' do
      expect(described_class.status_dictionary).to eq(deleted: 0, active: 1, inactive: 2)
    end
  end

  describe 'Rails requirement' do
    it 'raises when loaded outside a Rails project' do
      hide_const('Rails')

      expect { load File.expand_path('../lib/status_assignable.rb', __dir__) }
        .to raise_error(LoadError, 'The project is not a Rails project!')
    end
  end

  describe '.[]' do
    it 'adds custom statuses for the next model that includes the concern' do
      model = build_model(include_concern: false)

      model.include(described_class[pending: 3])

      expect(model.enum_definition).to eq(
        [:status, { deleted: 0, active: 1, inactive: 2, pending: 3 }]
      )
      expect(described_class.status_dictionary).to eq(deleted: 0, active: 1, inactive: 2)
    end

    it 'rejects overridden default statuses' do
      expect { described_class[deleted: 3] }
        .to raise_error(ArgumentError, "Default statuses overridden. Don't do this.")
    end

    it 'rejects duplicate status values' do
      expect { described_class[pending: 1] }
        .to raise_error(ArgumentError, 'Status values must be unique.')
    end
  end

  describe 'inclusion' do
    it 'defines the status enum and archive methods' do
      model = build_model(include_concern: false)

      model.include(described_class)

      expect(model.enum_definition).to eq([:status, described_class::DEFAULT_STATUSES])
      expect(model.new).to respond_to(:soft_delete, :soft_destroy, :archive)
    end
  end

  describe '#soft_delete' do
    it 'archives associations and directly updates the record' do
      record = build_model.new
      params = { status: 'deleted' }

      expect(record).to receive(:archive_associations).ordered
      expect(record).to receive(:archive_params).and_return(params).ordered
      expect(record).to receive(:update_columns).with(params).and_return(true).ordered

      expect(record.soft_delete).to be(record)
    end

    it 'returns false when its transaction fails' do
      record = build_model.new
      allow(record).to receive(:transaction).and_return(false)

      expect(record.soft_delete).to be(false)
    end
  end

  describe '#soft_destroy' do
    it 'runs callbacks, archives associations, and updates the record' do
      record = build_model.new
      params = { status: 'deleted' }

      expect(record).to receive(:run_callbacks).with(:soft_destroy).and_yield.and_return(true)
      expect(record).to receive(:archive_associations).ordered
      expect(record).to receive(:set_paper_trail_event).ordered
      expect(record).to receive(:archive_params).and_return(params).ordered
      expect(record).to receive(:update).with(params).and_return(true).ordered

      expect(record.soft_destroy).to be(record)
    end

    it 'returns false when its transaction fails' do
      record = build_model.new
      allow(record).to receive(:transaction).and_return(false)

      expect(record.soft_destroy).to be(false)
    end
  end

  describe 'archive helpers' do
    it 'builds and memoizes archive parameters' do
      record = build_model.new

      params = record.send(:archive_params)

      expect(params).to include(status: 'deleted')
      expect(params[:updated_at]).to be_present
      expect(record.send(:archive_params)).to be(params)
    end

    it 'filters and memoizes archivable associations' do
      archived = association(:posts, archive: :callbacks)
      ignored = association(:profile, {})
      record = build_model(reflections: [archived, ignored]).new

      expect(record.send(:archivable_associations)).to eq([archived])
      expect(record.send(:archivable_associations)).to be(record.send(:archivable_associations))
    end

    it 'archives each association with its configured strategy' do
      callbacks_records = [double(soft_destroy: nil)]
      assign_records = double
      destroyed_records = [double(destroy: nil)]
      nullified_records = double
      reflections = [
        association(:callback_records, archive: :callbacks),
        association(:assign_records, archive: :assign),
        association(:destroyed_records, archive: :destroy),
        association(:nullified_records, { archive: :nullify }, :owner_id)
      ]
      record = build_model(reflections: reflections).new
      record.define_singleton_method(:callback_records) { callbacks_records }
      record.define_singleton_method(:assign_records) { assign_records }
      record.define_singleton_method(:destroyed_records) { destroyed_records }
      record.define_singleton_method(:nullified_records) { nullified_records }
      allow(assign_records).to receive(:update_all)
      allow(nullified_records).to receive(:update_all)

      record.send(:archive_associations)

      expect(callbacks_records.first).to have_received(:soft_destroy)
      expect(assign_records).to have_received(:update_all).with(record.send(:archive_params))
      expect(destroyed_records.first).to have_received(:destroy)
      expect(nullified_records).to have_received(:update_all).with(owner_id: nil)
    end

    it 'handles singular and missing association records' do
      record = build_model.new
      callback_record = double
      assign_record = double
      destroy_record = double
      nullify_record = double
      association_reflection = association(:profile, { archive: :nullify }, :owner_id)
      allow(callback_record).to receive(:soft_destroy)
      allow(assign_record).to receive(:update_columns)
      allow(destroy_record).to receive(:destroy)
      allow(nullify_record).to receive(:update_column)

      record.send(:callbacks_method, callback_record)
      record.send(:callbacks_method, nil)
      record.send(:assign_method, assign_record)
      record.send(:assign_method, nil)
      record.send(:destroy_method, destroy_record)
      record.send(:destroy_method, nil)
      record.send(:nullify_method, nullify_record, association_reflection)
      record.send(:nullify_method, nil, association_reflection)

      expect(callback_record).to have_received(:soft_destroy)
      expect(assign_record).to have_received(:update_columns).with(record.send(:archive_params))
      expect(destroy_record).to have_received(:destroy)
      expect(nullify_record).to have_received(:update_column).with(:owner_id, nil)
    end
  end

  describe 'PaperTrail integration' do
    it 'does not set an event when PaperTrail is unavailable' do
      record = build_model.new

      record.send(:set_paper_trail_event)

      expect(record.paper_trail_event).to be_nil
    end

    it 'sets a destroy event when PaperTrail is enabled for the model' do
      record = build_model.new
      request = double(enabled_for_model?: true)
      stub_const('PaperTrail', Class.new)
      allow(PaperTrail).to receive(:request).and_return(request)

      record.send(:set_paper_trail_event)

      expect(record.paper_trail_event).to eq('destroy')
    end
  end

  def build_model(reflections: [], include_concern: true)
    model = Class.new do
      attr_accessor :paper_trail_event

      class << self
        attr_accessor :enum_definition, :reflections

        def define_callbacks(*)
          nil
        end

        def enum(name, values)
          @enum_definition = [name, values]
        end

        def reflect_on_all_associations
          reflections
        end
      end

      def transaction
        yield
      end

      def run_callbacks(*)
        yield
      end

      def update_columns(*)
        true
      end

      def update(*)
        true
      end
    end

    model.reflections = reflections
    model.include(described_class) if include_concern
    model
  end

  def association(name, options, foreign_key = nil)
    Struct.new(:name, :options, :foreign_key).new(name, options, foreign_key)
  end
end
