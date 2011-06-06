class CalcDB
  Calc = Struct.new("Calc", :owner, :str)

  def initialize(file)
    @calcs = Hash.new
    @file = file
    import()
  end

  def calc(calc)
    result = @calcs[calc]
    return result ? result.str : nil
  end

  def owncalc(calc)
    result = @calcs[calc]
    return result ? result.owner : nil
  end

  def searchcalc(pattern, limit=-1)
    result = Array.new
    @calcs.each do |calc_name, calc|
      result.push(calc_name) if pattern === calc.str
      if result.size == limit then
        result.push("<list truncated at #{limit}>")
        return result
      end
    end
    return result
  end

  def listcalc(pattern, limit=-1)
    result = Array.new
    @calcs.each do |calc_name, calc|
      result.push(calc_name) if pattern === calc_name
      if result.size == limit then
        result.push("<list truncated at #{limit}>")
        return result
      end
    end
    return result
  end

  def mkcalc(owner, calc, str)
    @calcs[calc] = Calc.new(owner, str)
    export()
  end

  def rmcalc(owner, calc)
    @calcs.delete(calc)
    export()
  end

  def import()
    File.open(@file, 'r') do |input|
      input.each_line do |line|
        case line
        when /(.+?)\s(.+?)\|(.*)/
          @calcs[$1] = Calc.new($2, $3)
        else
          puts "Warning: line not parsed: #{line}"
        end
      end
    end
  end

  def export()
    # TODO: If this throws an exception, the file may be left in an incomplete
    # state.
    File.open(@file, 'w') do |output|
      @calcs.each do |calc_name, calc|
        puts "#{calc_name} #{calc.owner}|#{calc.str}"
      end
    end
  end
end

