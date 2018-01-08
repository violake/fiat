Dir[File.dirname(__FILE__) + '/validation/*.rb'].each {|file| require file }

module Fiat
  PAYMENTIMPORT_TYPE = Dir["app/models/payments/*.rb"].map!{|file| file.split("/").last.split(".").first }
  TRANSFERIMPORT_TYPE = Dir["app/models/transfers/*.rb"].map!{|file| file.split("/").last.split(".").first }

  module Validation

    ## check csv lines validation
    #  [params]
    #  nil
    #  [return]
    #  nil
    #  [used attribute:]
    #  @column_name : array(symbol)  -- check necessary column names not missing
    #  @transactions    : array(hash)    -- check transaction type valid
    ##
    def check
      # check validation according to transaction type 
      if @source_type == nil || @source_type == "" || !("Fiat::"+self.class.to_s.split("::").last.upcase+"_TYPE").constantize.include?(@source_type)
        raise "Import failed: source type unknow '#{@source_type}' !!"
      end
      validateclass = Fiat.const_get("#{@source_type.capitalize}Validation")
      missing = validateclass.check_columnname(@column_names)
      raise "Import failed: column missing - [#{missing.to_a.join(",")}]" if missing.size > 0

      #filter data if needed
      @transactions = validateclass.filter(@transactions) if validateclass.respond_to?("filter")
      raise "Import failed: #{@transactions}" if @transactions.is_a? String

      @transactions.each_with_index do |transaction,index|
        valid, errormsg = validateclass.validate(transaction)
        raise "Import failed: transactions data error - #{errormsg} in line #{index+2} !!" unless valid
      end
    end
  end
end