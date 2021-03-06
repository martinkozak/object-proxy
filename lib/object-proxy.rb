# encoding: utf-8
# (c) 2011 Martin Kozák (martinkozak@martinkozak.net)

require "hash-utils/symbol" # >= 0.13.0
require "hash-utils/object" 

##
# Main ObjectProxy class.
#

module ObjectProxy

    ##
    # Creates proxy object. "Proxy object" means, it calls handler
    # if defined before and after each method call.
    #
    # @param [Object, Class] object proxied object or class 
    # @return [Object, Class] anonymous proxy instance or class with before and after 
    #   handlers functionality
    # @since 0.2.0
    #

    def self.proxy(object)
        
        ### Takes class object
        
        _class = object
        if not _class.kind_of? Class
            _class = object.class
        end
        
        ### Defines class
        
        cls = Class::new(_class)
        cls.instance_eval do
        
            # Eviscerates instances methods and replace them by
            #   before and after handlers invoker
            public_instance_methods.each do |method|
                if not method.in? [:object_id, :__send__]
                    define_method method do |*args, &block|
                        before = method.prepend("before_")
                        after = method.prepend("after_")
                        
                        # before handler
                        if @handlers.include? before
                            args, block = @handlers[before].call(args, block)
                        end
                        
                        # call
                        result = @wrapped.send(method, *args, &block)
                        
                        # after handler
                        if @handlers.include? after
                            result = @handlers[after].call(result)
                        end
                        
                        return result
                    end
                end
            end
            
            # Adds constructor
            if object.kind_of? Class
                define_method :initialize do |*args, &block|
                    @handlers = { }
                    @wrapped = _class::new(*args, &block)
                end
            else
                define_method :initialize do |*args, &block|
                    @handlers = { }
                    @wrapped = object
                end            
            end
            
            # Event handlers assigning interceptor
            define_method :method_missing do |name, *args, &block|
                if name.start_with? "before_", "after_"
                    self.register_handler(name, &block)
                end
            end
            
            # Assigns event handler
            define_method :register_handler do |name, &block|
                @handlers[name] = block
            end
            
            # Wrapped accessor
            
            attr_accessor :wrapped

        end
        
        if object.kind_of? Class
            result = cls
        else
            result = cls::new
        end
        
        return result
    end
    
    ##
    # Alias for +ObjectProxy::proxy+.
    #
    # @param [Object, Class] object
    # @return [Object, Class]
    # @since 0.2.0
    #
    
    def self.[](object)
        self::proxy(object)
    end
        
    ##
    # Alias for +ObjectProxy::proxy+.
    #
    # @param [Object, Class] object
    # @return [Object, Class]
    # @since 0.1.0
    #
    
    def self.create(object)
        self::proxy(object)
    end
    
    ##
    # Creates fake object. "Fake object" means, all methods are replaced
    # by empty functions or defined bodies.
    #
    # Original class public instance functions are aliased to form: 
    # +native_<name of function>+.
    #
    # @param [Class] cls class for fake
    # @param [Proc] block block with definitions of custom methods 
    #   which will be run in private context of the faked class
    # @return [Class] anonymous class faked object
    # @since 0.2.0
    #
    
    def self.fake(cls, omit = [ ], &block)
        cls = Class::new(cls)
        cls.instance_eval do
            omit.concat([:object_id, :__send__])
            
            # Eviscerates instances methods and replace them by
            #   before and after handlers invoker
            public_instance_methods.each do |method|
                if not method.in? omit
                    alias_method method.prepend("native_"), method
                    define_method method do |*args, &block| end
                end
            end
        end
        
        if not block.nil?
            cls.instance_eval(&block)
        end
        
        return cls
    end
    
    ##
    # Creates "tracker object". Works by similar way as standard proxy
    # objects, but rather than invoking individual handlers for each 
    # method call invokes single handler before and single after call
    # which receives except arguments or result the method name.
    #
    # Also doesn't support customizing the arguments or result.
    #
    # @param [Object, Class] object proxied object or class 
    # @return [Object, Class] anonymous proxy instance or class with before and after 
    #   handlers functionality
    # @since 0.2.0
    #
    
    def self.track(object)
        
        ### Takes class object
        
        _class = object
        if not _class.kind_of? Class
            _class = object.class
        end
        
        ### Defines class
        
        cls = Class::new(_class)
        cls.class_eval do
        
            # Eviscerates instances methods and replace them by 
            # +#on_method+ invoker
            
            public_instance_methods.each do |method|
                if not method.in? [:object_id, :__send__, :class]
                    define_method method do |*args, &block| 
                        if not @before_call.nil?
                            @before_call.call(method, args, block)
                        end
                        
                        result = @wrapped.send(method, *args, &block)
                        
                        if not @after_call.nil?
                            @after_call.call(method, result)
                        end
                        
                        return result
                    end
                end
            end
            
            # Adds constructor
            
            if object.kind_of? Class
                define_method :initialize do |*args, &block|
                    @wrapped = _class::new(*args, &block)
                end                
            else
                define_method :initialize do |*args, &block|
                    @wrapped = object
                end                
            end
            
            # Defines handler assigners
            
            define_method :before_call do |&block|
                @before_call = block
            end
            
            define_method :after_call do |&block|
                @after_call = block
            end
            
            # Wrapped accessor
            
            attr_accessor :wrapped
                                    
        end
        
        if object.kind_of? Class
            result = cls
        else
            result = cls::new
        end
        
        return result
    end

    ##
    # Creates "catching object". It means, it catches all method calls
    # and forwards them to +#method_call+ handler which calls wrapped object
    # by default, but can be overriden, so calls can be controlled.
    #
    # @param [Object, Class] object proxied object or class
    # @param [Proc] block  default +#method_call+ handler for whole class 
    # @return [Object, Class] anonymous proxy instance or class
    # @since 0.2.0
    #
    
    def self.catch(object, &block)
        
        ### Takes class object
        
        _class = object
        if not _class.kind_of? Class
            _class = object.class
        end
        
        ### Defines class
        
        cls = Class::new(_class)
        cls.class_eval do

            # Eviscerates instances methods and replace them by 
            # +#handle_call+ invoker
            
            public_instance_methods.each do |method|
                if not method.in? [:object_id, :__send__, :class]
                    define_method method do |*args, &block|
                        self.method_call.call(method, args, block)
                    end
                end
            end
            
            # Adds constructor

            if not object.kind_of? Class
                define_method :initialize do |&block|
                    @wrapped = object
                    
                    if not block.nil?
                       @method_call = block 
                    else
                       @method_call = cls.class_variable_get(:@@method_call)
                    end
                    
                    if @method_call.nil?
                        @method_call = Proc::new do |method, args, block|
                            @wrapped.send(method, *args, &block)
                        end
                    end
                end
            else
                define_method :initialize do |*args, &block|
                    @wrapped = _class::new(*args, &block)
                    
                    ic = cls.class_variable_get(:@@instance_created)
                    if not ic.nil?
                        ic.call(self)
                    end
                end                
            end
             
            # Defines handler assigners
            
            class_variable_set(:@@method_call, nil)
            define_singleton_method :method_call do |&block| 
                cls.class_variable_set(:@@method_call, block)
            end
            
            class_variable_set(:@@instance_created, nil)
            define_singleton_method :instance_created do |&block| 
                cls.class_variable_set(:@@instance_created, block)
            end
            
            # Sets up accessors and default handler            
            attr_accessor :wrapped

            define_method :method_call do |&block|
                if not block.nil?   # set
                    @method_call = block
                else                # get
                    result = @method_call
                    
                    if result.nil?
                        result = Proc::new do |method, args, block|
                            @wrapped.send(method, *args, &block)
                        end
                    end                    
                    
                    return result
                end
            end
            
            attr_writer :method_call
                        
        end
        
        if object.kind_of? Class
            result = cls
        else
            result = cls::new
        end
        
        return result
        
    end    
end

##
# Alias for {ObjectProxy}.
#

OP = ObjectProxy

