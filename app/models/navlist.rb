class Nav
  attr_accessor :name, :href
  def initialize(name, href)
    @name = name
    @href = href
  end
end

class Navlist
attr_accessor :nav_list
  def initialize()    
  end

  def initialize(navigation)
    n = navigation.list.split('=(_8^(1)')
    h = navigation.href_list.split
    @nav_list = []
    0.upto(n.size - 1) do |i|
      @nav_list << Nav.new(n[i], h[i])
    end
  end 
  
  def add(name, href)
    @nav_list << Nav.new(name, href) 
  end
  
  def copy
    temp = []
    @nav_list.each_index do |i|
      temp << Nav.new(@nav_list[i].name, @nav_list[i].href)
    end
    return temp
  end
end
