require_relative 'test_helper'

checked_describe 'tilt/erubi' do
  it "registered for '.erubi' files" do
    assert_equal Tilt::ErubiTemplate, Tilt['test.erubi']
    assert_equal Tilt::ErubiTemplate, Tilt['test.html.erubi']
  end

  it "registered above ERB and Erubis" do
    %w[erb rhtml].each do |ext|
      lazy = Tilt.lazy_map[ext]
      erubi_idx = lazy.index { |klass, file| klass == 'Tilt::ErubiTemplate' }
      erubis_idx = lazy.index { |klass, file| klass == 'Tilt::ErubisTemplate' }
      erb_idx = lazy.index { |klass, file| klass == 'Tilt::ERBTemplate' }
      assert erubi_idx < erubis_idx,
        "#{erubi_idx} should be lower than #{erubis_idx}"
      assert erubi_idx < erb_idx,
        "#{erubi_idx} should be lower than #{erb_idx}"
    end
  end

  it "preparing and evaluating templates on #render" do
    template = Tilt::ErubiTemplate.new { |t| "Hello World!" }
    assert_equal "Hello World!", template.render
  end

  it "can be rendered more than once" do
    template = Tilt::ErubiTemplate.new { |t| "Hello World!" }
    3.times { assert_equal "Hello World!", template.render }
  end

  it "passing locals" do
    template = Tilt::ErubiTemplate.new { 'Hey <%= name %>!' }
    assert_equal "Hey Joe!", template.render(Object.new, :name => 'Joe')
  end

  it "evaluating in an object scope" do
    template = Tilt::ErubiTemplate.new { 'Hey <%= @name %>!' }
    scope = Object.new
    scope.instance_variable_set :@name, 'Joe'
    assert_equal "Hey Joe!", template.render(scope)
  end

  it "exposing the buffer to the template by default" do
    template = Tilt::ErubiTemplate.new(nil, :bufvar=>'@_out_buf') { '<% self.exposed_buffer = @_out_buf %>hey' }
    scope = Class.new do
      attr_accessor :exposed_buffer
    end.new

    template.render(scope)
    refute_nil scope.exposed_buffer
    assert_equal scope.exposed_buffer, 'hey'
  end

  it "passing a block for yield" do
    template = Tilt::ErubiTemplate.new { 'Hey <%= yield %>!' }
    assert_equal "Hey Joe!", template.render { 'Joe' }
  end

  it "backtrace file and line reporting without locals" do
    data = File.read(__FILE__).split("\n__END__\n").last
    fail unless data[0] == ?<
    template = Tilt::ErubiTemplate.new('test.erubis', 11) { data }
    begin
      template.render
      fail 'should have raised an exception'
    rescue => boom
      assert_kind_of NameError, boom
      line = boom.backtrace.grep(/\Atest\.erubis:/).first
      assert line, "Backtrace didn't contain test.erubis"
      _file, line, _meth = line.split(":")
      assert_equal '13', line
    end
  end

  it "backtrace file and line reporting with locals" do
    data = File.read(__FILE__).split("\n__END__\n").last
    fail unless data[0] == ?<
    template = Tilt::ErubiTemplate.new('test.erubis', 1) { data }
    begin
      template.render(nil, :name => 'Joe', :foo => 'bar')
      fail 'should have raised an exception'
    rescue => boom
      assert_kind_of RuntimeError, boom
      line = boom.backtrace.first
      file, line, _meth = line.split(":")
      assert_equal 'test.erubis', file
      assert_equal '6', line
    end
  end

  it "erubis template options" do
    template = Tilt::ErubiTemplate.new(nil, :escapefunc=> 'h') { 'Hey <%== @name %>!' }
    scope = Object.new
    def scope.h(s) s * 2 end
    scope.instance_variable_set :@name, 'Joe'
    assert_equal "Hey JoeJoe!", template.render(scope)
  end

  it "using an instance variable as the outvar" do
    template = Tilt::ErubiTemplate.new(nil, :outvar => '@buf') { "<%= 1 + 1 %>" }
    scope = Object.new
    scope.instance_variable_set(:@buf, 'original value')
    assert_equal '2', template.render(scope)
    assert_equal 'original value', scope.instance_variable_get(:@buf)
  end

  it "using Erubi::CaptureEndEngine subclass via :engine_class option" do
    require 'erubi/capture_end'
    def self.bar
      @a << "a"
      yield
      @a << 'b'
      @a.upcase
    end
    template = Tilt::ErubiTemplate.new(nil, :engine_class => ::Erubi::CaptureEndEngine, :bufvar=>'@a') { 'c<%|= bar do %>d<%| end %>e' }
    assert_equal "cADBe", template.render(self)
  end

  it "using :escape_html => true option" do
    template = Tilt::ErubiTemplate.new(nil, :escape_html => true) { |t| %(<%= "<p>Hello World!</p>" %>) }
    assert_equal "&lt;p&gt;Hello World!&lt;/p&gt;", template.render
  end

  it "using :escape_html => false option" do
    template = Tilt::ErubiTemplate.new(nil, :escape_html => false) { |t| %(<%= "<p>Hello World!</p>" %>) }
    assert_equal "<p>Hello World!</p>", template.render
  end

  it "erubi default does not escape html" do
    template = Tilt::ErubiTemplate.new { |t| %(<%= "<p>Hello World!</p>" %>) }
    assert_equal "<p>Hello World!</p>", template.render
  end

  it "does not modify options argument" do
    options_hash = {:escape_html => true}
    Tilt::ErubiTemplate.new(nil, options_hash) { |t| "Hello World!" }
    assert_equal({:escape_html => true}, options_hash)
  end

  if RUBY_VERSION >= '2.3'
    it "uses frozen literal strings if :freeze option is used" do
      template = Tilt::ErubiTemplate.new(nil, :freeze => true) { |t| %(<%= "".frozen? %>) }
      assert_equal "true", template.render
    end
  end
end

__END__
<html>
<body>
    <h1>Hey <%= name %>!</h1>


    <p><% fail %></p>
</body>
</html>
