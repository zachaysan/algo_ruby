require "httparty"
require "yaml"
require "pp"

# Super duper alpha

class AlgoClient
  def initialize(key=nil)
    @key = key
    begin
      yaml = YAML.load_file(File.join(File.dirname(__FILE__), '../config/options.yml'))
      @options = yaml["api_location"]
    rescue
      $stderr.puts "problem loading options for #{self.class}"
    end
    # this should be replaced with a server call
    @methods = {
      "onetime_use_keys" => ["number_of_keys","usage_limit", "key"]
    }
    check_for_more_methods
    add_methods
  end
  
  def check_for_more_methods
    # merge in (or is it overwrite?) more methods (via get request) for @methods if they exisit
  end

  # This part may be confusing.
  def add_methods
    # Gaining access to private method of Class
    method_me = AlgoClient.method(:define_method)
    
    @methods.each do |method_name, options|
      
      # define the method on the class
      method_me.call(method_name.to_sym) do |method_options|
        
        # Make sure every needed option is in the 
        options.each do |option|
          option = option.to_sym
          
          # Since it is often more convient to store the key on instantiation, 
          # a special check is made to make sure that if the key is non-existant
          # it is unimportant to the algo, provided that the key is there.
          $stderr.puts "\033[31mSTANDARD ERROR\033[0m: this method was expecting #{option} in the options, continuing anyways" unless method_options[option] or (!@key.nil? and option == :key)
          if option == :key
            method_options[:key] = @key if method_options[:key].nil?
          end
          
        end
        path = encode(method_name.to_s, method_options)
        HTTParty.get(url() + path)
      end
    end
  end
  
  def method_missing(method, *args, &block)
    number_of_methods = @methods.size
    check_for_more_methods
    if @methods.size == number_of_methods
      $stderr.puts "no algo by that name, going to generalized method missing"
      super
    end
    add_methods
    unless self.responds_to? method.to_sym
      $stderr.puts "there are new algos, but not by that name, going to generalized method missing"
      super
    end
    self.call(method.to_sym)
  end
  
  def url
    "https://#{@options["host"]}#{@options["path"]}"
  end

  def encode(method, params)
    # this is a hack because I forget the httparty shortcut right now
    query = method + "?"
    params.each do |k, v|
      query += k.to_s
      query += "="
      query += v.to_s
      query += "&"
    end
    query
  end

end

#  params["key"] = "hly4lg3whb6q2mf4"
algo = AlgoClient.new("hly4lg3whb6q2mf4")
pp algo.onetime_use_keys({:number_of_keys => 23, :usage_limit => 34})
#pp algo.methods
#number_of_keys","usage_limit"
