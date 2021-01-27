# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Rails::Delegate, :config do
  let(:cop_config) { { 'EnforceForPrefixed' => true } }
  let(:config) do
    merged = RuboCop::ConfigLoader
             .default_configuration['Rails/Delegate'].merge(cop_config)
    RuboCop::Config.new('Rails/Delegate' => merged)
  end

  it 'finds trivial delegate' do
    expect_offense(<<~RUBY)
      def foo
      ^^^ Use `delegate` to define delegations.
        bar.foo
      end
    RUBY
  end

  it 'finds trivial delegate with arguments' do
    expect_offense(<<~RUBY)
      def foo(baz)
      ^^^ Use `delegate` to define delegations.
        bar.foo(baz)
      end
    RUBY
  end

  it 'finds trivial delegate with prefix' do
    expect_offense(<<~RUBY)
      def bar_foo
      ^^^ Use `delegate` to define delegations.
        bar.foo
      end
    RUBY
  end

  it 'ignores class methods' do
    expect_no_offenses(<<~RUBY)
      def self.fox
        new.fox
      end
    RUBY
  end

  it 'ignores non trivial delegate' do
    expect_no_offenses(<<~RUBY)
      def fox
        bar.foo.fox
      end
    RUBY
  end

  it 'ignores trivial delegate with mismatched arguments' do
    expect_no_offenses(<<~RUBY)
      def fox(baz)
        bar.fox(foo)
      end
    RUBY
  end

  it 'ignores trivial delegate with optional argument with a default value' do
    expect_no_offenses(<<~RUBY)
      def fox(foo = nil)
        bar.fox(foo || 5)
      end
    RUBY
  end

  it 'ignores trivial delegate with mismatched number of arguments' do
    expect_no_offenses(<<~RUBY)
      def fox(a, baz)
        bar.fox(a)
      end
    RUBY
  end

  it 'ignores trivial delegate with mismatched keyword arguments' do
    expect_no_offenses(<<~RUBY)
      def fox(foo:)
        bar.fox(foo)
      end
    RUBY
  end

  it 'ignores trivial delegate with other prefix' do
    expect_no_offenses(<<~RUBY)
      def fox_foo
        bar.foo
      end
    RUBY
  end

  it 'ignores methods with arguments' do
    expect_no_offenses(<<~RUBY)
      def fox(bar)
        bar.fox
      end
    RUBY
  end

  it 'ignores the method in the body with arguments' do
    expect_no_offenses(<<~RUBY)
      def fox
        bar(42).fox
      end
    RUBY
  end

  it 'ignores private delegations' do
    expect_no_offenses(<<~RUBY)
      private def fox # leading spaces are on purpose
        bar.fox
      end

        private

      def fox
        bar.fox
      end
    RUBY
  end

  it 'ignores protected delegations' do
    expect_no_offenses(<<~RUBY)
      protected def fox # leading spaces are on purpose
        bar.fox
      end

      protected

      def fox
        bar.fox
      end
    RUBY
  end

  it 'ignores delegation with assignment' do
    expect_no_offenses(<<~RUBY)
      def new
        @bar = Foo.new
      end
    RUBY
  end

  it 'ignores delegation to constant' do
    expect_no_offenses(<<~RUBY)
      FOO = []
      def size
        FOO.size
      end
    RUBY
  end

  it 'ignores code with no receiver' do
    expect_no_offenses(<<~RUBY)
      def change
        add_column :images, :size, :integer
      end
    RUBY
  end

  context 'with EnforceForPrefixed: false' do
    let(:cop_config) do
      { 'EnforceForPrefixed' => false }
    end

    it 'ignores trivial delegate with prefix' do
      expect_no_offenses(<<~RUBY)
        def bar_foo
          bar.foo
        end
      RUBY
    end
  end

  it 'ignores trivial delegate with safe navigation' do
    expect_no_offenses(<<~RUBY)
      def foo
        bar&.foo
      end
    RUBY
  end

  describe '#autocorrect' do
    context 'trivial delegation' do
      let(:source) do
        <<~RUBY
          def bar
            foo.bar
          end
        RUBY
      end

      let(:corrected_source) do
        <<~RUBY
          delegate :bar, to: :foo
        RUBY
      end

      it 'autocorrects' do
        expect(autocorrect_source(source)).to eq(corrected_source)
      end
    end

    context 'trivial delegation with prefix' do
      let(:source) do
        <<~RUBY
          def foo_bar
            foo.bar
          end
        RUBY
      end

      let(:corrected_source) do
        <<~RUBY
          delegate :bar, to: :foo, prefix: true
        RUBY
      end

      it 'autocorrects' do
        expect(autocorrect_source(source)).to eq(corrected_source)
      end

      context 'with EnforceForPrefixed: false' do
        let(:cop_config) do
          { 'EnforceForPrefixed' => false }
        end

        it 'does not autocorrect' do
          expect(autocorrect_source(source)).to eq(source)
        end
      end
    end
  end
end
