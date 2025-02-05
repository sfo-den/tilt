require_relative 'test_helper'
require 'tilt/csv'

describe 'tilt/csv' do
  it "registered for '.rcsv' files" do
    assert_equal Tilt::CSVTemplate, Tilt['rcsv']
  end

  it "compiles and evaluates the template on #render" do
    template = Tilt::CSVTemplate.new { "csv << ['hello', 'world']" }
    assert_equal "hello,world\n", template.render
  end

  it "can be rendered more than once" do
    template = Tilt::CSVTemplate.new { "csv << [1,2,3]" }
    3.times { assert_equal "1,2,3\n", template.render }
  end

  it "can pass locals" do
    template = Tilt::CSVTemplate.new { 'csv << [1, name]' }
    assert_equal "1,Joe\n", template.render(Object.new, :name => 'Joe')
  end

  it "evaluating in an object scope" do
    template = Tilt::CSVTemplate.new { 'csv << [1, @name]' }
    scope = Object.new
    scope.instance_variable_set :@name, 'Joe'
    assert_equal "1,Joe\n", template.render(scope)
  end

  it "backtrace file and line reporting" do
    data = File.read(__FILE__).split("\n__END__\n").last
    template = Tilt::CSVTemplate.new('test.csv') { data }
    begin
      template.render
      fail 'should have raised an exception'
    rescue => boom
      assert_kind_of NameError, boom
      line = boom.backtrace.grep(/\Atest\.csv:/).first
      assert line, "Backtrace didn't contain test.csv"
      _file, line, _meth = line.split(":")
      assert_equal '4', line
    end
  end

  it "passing options to engine" do
    template = Tilt::CSVTemplate.new(:col_sep => '|') { 'csv << [1,2,3]' }
    assert_equal "1|2|3\n", template.render
  end

  it "outvar option" do
    outvar = '@_output'
    scope = Object.new
    template = Tilt::CSVTemplate.new(:outvar => outvar) { 'csv << [1,2,3]' }
    output = template.render(scope)
    assert_equal output, scope.instance_variable_get(outvar.to_sym)
  end
end

__END__
# header
csv << ['Type', 'Age']

raise NameError

# rows
csv << ['Frog', 2]
csv << ['Cat', 5]
