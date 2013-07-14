class ChangesInput
  def initialize(data)
    @data = data
  end

  def repo
    @repo ||= "#{@data[:org]}/#{@data[:repo]}"
  end

  def base
    @data[:base]
  end

  def target
    @data[:target]
  end
end
