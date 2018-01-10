Dir[File.dirname(__FILE__) + '/validation/transfer_ins/*.rb'].each {|file| require file }
Dir[File.dirname(__FILE__) + '/validation/transfer_outs/*.rb'].each {|file| require file }

module Fiat
  TRANSFERINIMPORT_TYPE = Dir["app/models/transfer_ins/*.rb"].map!{|file| file.split("/").last.split(".").first }
  TRANSFEROUTIMPORT_TYPE = Dir["app/models/transfer_outs/*.rb"].map!{|file| file.split("/").last.split(".").first }

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
        import_failed "source type unknow '#{@source_type}' !!"
      end
      validate_class = @module.constantize.const_get("#{@source_type.capitalize}Validation")
      missing = validate_class.check_columnname(@column_names)
      import_failed "column missing - [#{missing.to_a.join(",")}]" if missing.size > 0

      #filter data if needed
      @transactions = validate_class.filter(@transactions) if validate_class.respond_to?("filter")
      import_failed @transactions if @transactions.is_a? String

      @transactions.each_with_index do |transaction,index|
        valid, errormsg = validate_class.validate(transaction)
        import_failed "transactions data error - #{errormsg} in line #{index+2} !!" unless valid
      end
    end

    def import_failed(message)
      raise "Import failed: #{message}"
    end
  end
end
