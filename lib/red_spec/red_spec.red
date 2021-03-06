# Spec::DSL (module)
#   should_fail
#   should_be
#   should_not_be
#   should_be_empty
#   should_not_be_empty
#   should_be_true
#   should_not_be_true
#   should_be_false
#   should_not_be_false
#   should_be_nil
#   should_not_be_nil
#   should_have
#   should_not_have
#   should_have_exactly
#   should_have_at_least
#   should_have_at_most
#   should_include
#   should_not_include
#   should_match
#   should_not_match
#

# RedSpec is a BDD library designed for Red (url)
# RedSpec draws inspiration from both Ruby RSpec and Javascript JSSpec
# Using:
# RedSpec is intended for use with Red Herring, the framework-independant Red runner (url)

module DSL
  # +DSL::Base+ represents the basic syntax that all Red objects should have to
  # work properly with RedSpec. It also includes stub methods for methods that 
  # only object of a specific type should have. These methods will raise Specs::Failure when
  # called because calling them on any object that does not include their
  # fully implemented versions implies a specification that behaves 
  # differently than expected.
  # 
  module Base
    def should_equal(other)
      raise ::Specs::Failure unless self == other
      true
    end
    
    def should_be(other)
      raise ::Specs::Failure unless self === other
      true
    end
  
    def should_not_be(other)
      raise ::Specs::Failure if self === other
      true
    end
  
    def should_not_equal(other)
      raise ::Specs::Failure if self == other
      true
    end
    
    def should_not_be_nil
      raise ::Specs::Failure if self == nil
    end
    
    def should_be_kind_of(klass)
      raise ::Specs::Failure unless self.class == klass
    end
  
    # TODO: implement
    def behaves_like(a,b); true; end
    def should_receive(*args); true; end

    # here for polymorphic purposes. all objects will need to respond
    # to these but having these methods called implies you are
    # are not getting a object you intended. 
    #
    # For example, calling .should_be_true on an object that is 
    # not _true_ implies a specification failure by defintaiton
    # and will raise Specs::Failure
    def should_be_nil;      raise ::Specs::Failure; end
    def should_be_true;     raise ::Specs::Failure; end
    def should_be_false;    raise ::Specs::Failure; end
    def should_have(n);     raise ::Specs::Failure; end
    def items;              raise ::Specs::Failure; end
  end
  
  # 
  module Nil
    def should_be_nil
      raise ::Specs::Failure unless self == nil
    end
    
    def should_not_be_nil
      raise ::Specs::Failure if self == nil
    end
  end
  
  module Boolean
    def should_be_true
      raise ::Specs::Failure unless `this.valueOf()`
    end
    
    def should_be_false
       raise ::Specs::Failure if `this.valueOf()`
    end
  end
  
  module Proc
    # TODO: implement
    def should_raise(specific_exception = nil)
      
    end
    
    # TODO: implement
    def should_not_raise(specific_exception = nil)
      
    end
  end
  
  module Array
    def should_have(n)
      raise ::Specs::Failure unless self.size == n
    end
    
    # just for looks to allow sugary syntax like
    # @foo.bar.should_have(2).items
    def items
      true
    end
  end
end

String.include(DSL::Base)
Array.include(DSL::Base)
Hash.include(DSL::Base)
Numeric.include(DSL::Base)
Class.include(DSL::Base)
nil.extend(DSL::Base)
nil.extend(DSL::Nil)

`Red.donateMethodsToClass(#{DSL::Boolean}.prototype, Boolean.prototype)`

Array.include(DSL::Array)
Proc.include(DSL::Proc)


# Just stores the @@spec_list class variables. @@spec_list is an array of
# all the specs created with Spec.describe. This might go away with everthing nested inside
# of class Spec
class RedSpec
  @@specs_list = []
  def self.specs
    @@specs_list
  end
  
  def self.escape_tags(string)
    return string
  end
end

class Spec  
  attr_accessor :name, :block, :before_each_block, :examples, :runner, :description
  
  def self.describe(name, &block)
    s = Spec.new(name, &block)
    RedSpec.specs << s
    block.call(s)
  end
  
  def initialize(name, &block)
    @name  =  name.to_s
    @description = ''
    @before_all_block   = lambda {true}
    @before_each_block  = lambda {true}
    @block = block
    @examples = []
  end
  
  def before(type, &block)
    if type == :each
      @before_each_block = block
    else
      @before_all_block  = block
      @before_all_block.call
    end
  end
  
  # the meat of the verb calls on 'it' ('can', 'has', 'does', 'wants', etc).
  # allows us to add new verbs and stay DRY.
  def verb(display_verb, description, proc)
    self.examples << ::Specs::Example.new((display_verb + " " + description), self, proc)
  end
  
  def can(description, &block)
    self.verb("can", description, &block)
  end
  
  def returns(description, &block)
     self.verb("returns", description, &block)
  end
  
  def has(description, &block)
    self.verb("has", description, &block)
  end
  
  def does_not(description, &block)
    self.verb("does not", description, &block)
  end
  
  def tries(description, &block)
    self.verb("tries", description, &block)
  end
  
  def checks(description, &block)
    self.verb("checks", description, &block)
  end
  
  def yields(description, &block)
    self.verb("yields", description, &block)
  end
  
  def will(description, &block)
    self.verb("will", description, &block)
  end
  
  def is_not(description, &block)
    self.verb("is not", description, &block)
  end
  
  def raises(description, &block)
    self.verb("raises", description, &block)
  end
  
  def behaves_like(the_one, the_other); true; end
  
  def to_heading_html
    "<li id=\"spec_#{self.object_id.to_s}_list\"><h3><a href=\"#spec_#{self.object_id.to_s}\"> #{RedSpec.escape_tags(self.name)}</a> [<a href=\"?rerun=#{self.name}\">rerun</a>]</h3></li>"
  end
  
  def examples_to_html
    examples_as_text = []
    self.examples.each do |example|
      examples_as_text << example.to_html
    end
    examples_as_text.join('')
  end
  
  def to_html_with_examples
    "<li id=\"spec_#{self.object_id.to_s}\">
       <h3>#{RedSpec.escape_tags(self.name)} #{RedSpec.escape_tags(self.description)} [<a href=\"?rerun=#{self.name}\">rerun</a>]</h3>
       <ul id=\"spec_#{self.object_id.to_s}_examples\" class=\"examples\">
         #{self.examples_to_html}
       </ul>
     </li>
    "
  end

  def executor
    ::Specs::Executor.new(self)
  end
end

module Specs
  # class +MockObject+ provides a simple way to create anonymous objects
  # and spcificy their methods and return values
  class MockObject
    def initialize(value)
      @value = value
    end
    def should_receive(*args); true; end
    def with(*args); true; end
  end
  
  # class +Failure+ is raise when an +Example+ fails to behave as intended. 
  # +Failure+ is rescued by the +Runner+ which notes the failure and
  # continues to run subsequent Examples.
  class Failure < Exception; end
  
  # class +Error+ is raise when an +Example+ throws an error. Typically this
  # is caused by errors of javascript syntax, missing variables, etc. 
  # Many Ruby syntax errors will be discovered by Red at compile time when
  # ParseTree cannot parse the file.
  # +Error+ is rescued by the +Runner+ which notes the error and
  # continues to run subsequent Examples.
  class Error   < Exception; end
  
  # each block within a spec is an example.  typicall referenced with 'it' and one
  # of the action verb methods ('should', 'can', 'has', etc)
  # 
  # for example:
  # Spec.describe Foo do |it|
  # 
  #   it.has 'pretty damn awesome bars' do
  #     # I am an Example object and will be called by the Runner
  #   end
  # 
  # end
  #
  class Example
    attr_accessor :block, :name, :result, :spec
    def initialize(name, spec, &block)
      
      # Examples without blocks will be listed as 'pending'
      # and will not be executed by the Runner.
      self.result = "pending" if block.nil?
      @name  = name
      @spec  = spec
      @block = block
    end
    
    def to_html
      "<li id=\"example_#{self.object_id.to_s}\">
        <h4>#{RedSpec.escape_tags(self.name)}</h4>
       </li>
      "
    end
    
    def executor
      ::Specs::Executor.new(self)
    end
    
  end
  
  # responsible for gathering all specs from RedSpec.specs (or a subset if you're rerunning
  # a particual spec) into one place and running them.
  class Runner
    attr_accessor :specs, :specs_map, :total_examples, :logger, :ordered_executor, :total_failures, :total_errors, :total_pending
    def initialize(arg_specs, logger)
      logger.runner = self
      @logger = logger
      
      @specs = []
      @specs_map = {}
      
      self.total_examples = 0
      self.total_pending  = 0
      self.total_failures = 0
      self.total_errors   = 0
      self.add_all_specs(arg_specs)
    end
    
    def add_all_specs(specs)
      specs.each {|spec| self.add_spec(spec)}
    end
    
    def add_spec(spec)
      spec.runner = self
      self.specs << spec
      # self.specs_map[spec.object_id] = spec
      self.total_examples += spec.examples.size
    end
    
    def run
      self.logger.on_runner_start
      self.ordered_executor = Specs::OrderedExecutor.new
      self.specs.each do |spec|
        spec.examples.each do |example|
          self.ordered_executor.add_executor(example.executor)
        end
      end
      
      self.ordered_executor.run
      self.logger.on_runner_end
    end

    #     def get_spec_by_id          ; end
    #     def get_spec_by_context     ; end
    #     def has_exception           ; end
    #     def total_failures          ; end
    #     def total_errors            ; end
    #     def rerun                   ; end
     
  end
  
  # executes the code of the examples in each spec
  # and stores their state (success/failure) and any
  # failure messages, normalized for browser differences
  class Executor
    attr_accessor :example, :type, :containing_ordered_executor, :on_start
    
    def initialize(example)
      self.example  = example
    end
    
    def run
      ::Specs::Logger.on_example_start(self.example)
      #self.example.spec.before_block.call
      begin
        if self.example.result # result was set to pending on Example#initialize
          self.type = 'pending'
          self.example.spec.runner.total_pending += 1
        else
          `try {
            this.m$example().m$block().m$call();
           } catch(e) {
             #{raise ::Specs::Error}
           }`
        end
        
        self.type = 'success'
        self.example.result = 'success' unless self.example.result
        
      rescue ::Specs::Failure
        self.type = 'failure'
        self.example.result = 'failure'
        self.example.spec.runner.total_failures += 1
      rescue ::Specs::Error
        self.example.result = 'exception'   
        self.example.spec.runner.total_errors += 1        
      end
            
      ::Specs::Logger.on_example_end(self.example)
      
      self.containing_ordered_executor.next
    end
  end
  
  
  class OrderedExecutor
    attr_accessor :queue, :at
    
    def initialize
      @queue = []
      self.at = 0
    end
    
    def add_executor(executor)
      # some other stuff with callbacks? no idea
      executor.containing_ordered_executor = self
      self.queue << executor
    end
    
    # Runs the next Executor in the queue.
    def next
      self.at += 1
      self.queue[self.at].run unless self.at >= self.queue.size
    end
    
    def run
      if self.queue.size > 0
        self.queue[0].run
      end
    end
  end
  
  # Logger writes the pretty to the screen
  class Logger
    attr_accessor :runner, :started_at, :ended_at
    
    # on_runner_start is called just before the specs are run and writes the general logging
    # structure to the page for later manipulation
    def on_runner_start
      title = `document.title`
      self.started_at = Time.now
      # self.runnetotal_failures = 0
      
      # if container already exists it implies we are rerunning the 
      # specs and the contents of the div should be cleared.
      # Otherwise we added a containing div to the page
      # to hold our Logger printout.
      container = `document.getElementById('redspec_container')`
      if container
        `container.innerHTML = ""`
      else
        `container = document.createElement("DIV")`
        `container.id = "redspec_container"`
        `document.body.appendChild(container)`
      end
      
      # The dashboard contains at-a-glace information about the running/competed specs
      # allowing a tester to see see a summary of 
      `dashboard = document.createElement("DIV")`
      `dashboard.id = "dashboard"`
      `dashboard.innerHTML = [
        '<h1>RedSpec</h1>',
        '<ul>',
        // JSSpec.options.rerun ? '<li>[<a href="?" title="rerun all specs">X</a>] ' + JSSpec.util.escapeTags(decodeURIComponent(JSSpec.options.rerun)) + '</li>' : '',
        ' <li><span id="total_examples">' + #{self.runner.total_examples} + '</span> examples</li>',
        ' <li><span id="total_failures">0</span> failures</li>',
        ' <li><span id="total_errors">0</span> errors</li>',
        ' <li><span id="total_pending">0</span> pending</li>',
        ' <li><span id="progress">0</span>% done</li>',
        ' <li><span id="total_elapsed">0</span> secs</li>',
        '</ul>',
        '<p><a href="">RedSpec documentation</a></p>',
        ].join("");`
        
      `container.appendChild(dashboard);`
      
       # convert all of the specs for this runner into native js strings for writing
       all_runner_specs = []
       self.runner.specs.each do |spec|
         all_runner_specs << spec.to_heading_html
       end
       `all_runner_specs_as_list_items = #{all_runner_specs.join("")}.__value__`
       
      # List the Specs by name to act as a table of contents
      `list = document.createElement("DIV")`
      `list.id = "list"`
      `list.innerHTML = [
         '<h2>Specs</h2>',
         '<ul class="specs">',
         all_runner_specs_as_list_items,
        '</ul>'
         ].join("")`
      `container.appendChild(list)`
      
      
      # List all the examples, nested within their Spec name
      # so we can later manipulate their element to display
      # results of running a particular example.
      `log = document.createElement("DIV")`
      `log.id = "log"`
      
      all_runner_specs_with_examples = []
      self.runner.specs.each do |spec|
        all_runner_specs_with_examples << spec.to_html_with_examples
      end
      `all_runner_specs_as_list_items_with_examples = #{all_runner_specs_with_examples.join("")}.__value__`
      
      `log.innerHTML = [
        '<h2>Log</h2>',
        '<ul class="specs">',
        all_runner_specs_as_list_items_with_examples,
         '</ul>'
        ].join("")`
        
         `container.appendChild(log)`
    
      # add event click handler to each spec for toggling
      self.runner.specs.each do |spec|
        # `spec_div  = document.getElementById('spec_' + #{spec.object_id})`
        # `title = spec_div.getElementsByTagName("H3")[0]`
        # `title.onclick = function(e){
        #   var target = document.getElementById(this.parentNode.id + "_examples")
        #   target.style.display = target.style.display == 'none' ? 'block' : 'none'
        #   return true
        # }`
      end
    end
    
    # called automatically when a runner ends, updating the dashboard with result information for
    # the entire spec suite.
    def on_runner_end      
      `document.getElementById("total_elapsed").innerHTML  = (#{Time.now - self.started_at})`
      `document.getElementById("total_errors").innerHTML = #{self.runner.total_errors}`
      `document.getElementById("total_failures").innerHTML = #{self.runner.total_failures}`
      `document.getElementById("total_pending").innerHTML  = #{self.runner.total_pending}`
    end
        
    def self.on_spec_start(spec)
      `spec_list = document.getElementById("spec_" + spec.id + "_list")`
    	`spec_log = document.getElementById("spec_" + spec.id)`

    	`spec_list.className = "ongoing"`
    	`spec_log.className = "ongoing"`
    end
    
    def self.on_spec_end(spec)
      
    end
    
    # called before an example runs
    def self.on_example_start(example)
      `li = document.getElementById("example_" + #{example.object_id.to_s})`
      `li.className = "ongoing"`
    end
    
    # called after an example runs, manipulating the examples representation on the page
    # to reflect the result of the execution. 
    def self.on_example_end(example)
      `li = document.getElementById("example_" + #{example.object_id.to_s})`
      `li.className = #{example.result}.__value__`
    end
    
  end
end


main = lambda {
  if RedSpec.specs.size > 0
    r = Specs::Runner.new(RedSpec.specs, Specs::Logger.new)
    r.run
  end
}

# Wait for the window to load and then determing run the specs
# `window.onload = #{main}.__block__`

`m$mock = c$Specs.c$MockObject.m$new`
`m$describe = c$Spec.m$describe`
`m$before   = c$Spec.m$before`
`document.addEventListener('DOMContentLoaded', function(){document.__loaded__=true;#{main.call};}.m$(this), false)`
