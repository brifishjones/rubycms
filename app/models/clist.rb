class Clist
attr_accessor :contact_list
  
  def initialize(contact)
    if contact != nil
      @contact_list = contact.list.split('=(_8^(1)')
      0.upto(@contact_list.size - 1) do |i|
        @contact_list[i] = @contact_list[i].split('\n')
      end
    else
      @contact_list = []
      @contact_list << Array.new(1, 'Contact Information')
      @contact_list << Array.new(1, 'Phone:')
      @contact_list << Array.new(1, 'E-mail:')
      @contact_list[0][1] = '(Organization)'
      @contact_list[0][2] = '(Street Address)'
      @contact_list[0][3] = '(City, State Zip)'
      @contact_list[1][1] = '(Phone)'
      @contact_list[2][1] = '(E-mail)'
    end
  end 

end
