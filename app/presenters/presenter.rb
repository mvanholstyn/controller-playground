class Presenter
  def initialize(options = {})
    options.each do |key, value|
      send("#{key}=", value)
    end
  end
end