# used to encrypt and decrypt an entry in the database
# utilizes the crypt rubygem -- see crypt.rubyforge.org for more info
class Encrypter
  require 'crypt/blowfish'
  # pass in a list of attributes that should be stored encrypted in the database
  def initialize(attrs)
    @attrs = attrs
  end
  
  # encrypt fields before saving or updating
  def before_save(model)
    @attrs.each do |field|
      blowfish = Crypt::Blowfish.new("X@6g{kqI0(V;t~\h2Zg*L>:e$sY?MpB^cw}4,x_7vU/odK8H]1T)G3|l")  # key up to 56 bytes long
      encryptedBlock = blowfish.encrypt_string(model[field])
      # store as series of bytes in database to avoid SQLException unrecognized token error
      sob = ""
      encryptedBlock.each_byte {|c| sob << c.to_s + ' '}
      model[field] = sob.strip
    end
  end
  
  # decrypt after saving or finding
  def after_save(model)
    @attrs.each do |field|
      blowfish = Crypt::Blowfish.new("X@6g{kqI0(V;t~\h2Zg*L>:e$sY?MpB^cw}4,x_7vU/odK8H]1T)G3|l")  # key up to 56 bytes long
      ab = model[field].strip.split    # put series of bytes from db into an array
      s = ""
      ab.each {|c| s << c.to_i}   # recreate the encrypted block
      model[field] = blowfish.decrypt_string(s)
    end
  end
  
  # also call after_save after finding an existing record
  alias_method :after_find, :after_save
  
end

class ActiveRecord::Base
# in any model insert the following line to encrypt a column in the database
# encrypt(<name of column>)
# e.g. encrypt(:password)
# e.g. encrypt(:ssn) 
  def self.encrypt(*attr_names)
    encrypter = Encrypter.new(attr_names)
    
    before_save encrypter
    after_save encrypter
    after_find encrypter
    
    define_method(:after_find) {}    # for performance reasons define empty placeholder
    
  end
end
