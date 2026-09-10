# frozen_string_literal: true

RSpec.describe StatusAssignable::Association do
  let(:builder) { build_association_builder }

  describe '#valid_options' do
    it 'adds archive to the association options accepted by Rails' do
      expect(builder.new.send(:valid_options, %i[dependent inverse_of]))
        .to eq(%i[dependent inverse_of archive])
    end
  end

  describe '#define_callbacks' do
    it 'accepts every supported archive option and delegates to Rails' do
      described_class::VALID_ARCHIVE_OPTIONS.each do |archive_option|
        reflection = Struct.new(:options).new({ archive: archive_option })

        expect(builder.new.send(:define_callbacks, Object.new, reflection)).to eq(:defined)
      end
    end

    it 'delegates when archive is not configured' do
      reflection = Struct.new(:options).new({})

      expect(builder.new.send(:define_callbacks, Object.new, reflection)).to eq(:defined)
    end

    it 'rejects unsupported archive options' do
      reflection = Struct.new(:options).new({ archive: :invalid })

      expect { builder.new.send(:define_callbacks, Object.new, reflection) }
        .to raise_error(
          ArgumentError,
          'The :archive option must be one of [:callbacks, :assign, :destroy, :nullify], but is :invalid'
        )
    end
  end

  def build_association_builder
    Class.new do
      def valid_options(options)
        options
      end

      def define_callbacks(*)
        :defined
      end
    end.prepend(described_class)
  end
end
