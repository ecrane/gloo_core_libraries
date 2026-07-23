# Author::    Eric Crane  (mailto:eric.crane@mac.com)
# Copyright:: Copyright (c) 2025 Eric Crane.  All rights reserved.
#
# An HTML Form.
#
# A Form is the definition of a form, with a collection of form fields
#

module Objs
  class Form < Gloo::Core::Obj

    KEYWORD = 'form'.freeze
    KEYWORD_SHORT = 'form'.freeze

    # Form
    NAME = 'name'.freeze
    ID = 'id'.freeze
    METHOD = 'method'.freeze
    METHOD_DEFAULT = 'post'.freeze
    ACTION = 'action'.freeze
    CANCEL_PATH = 'cancel_path'.freeze
    CONTENT = 'content'.freeze
    STYLES = 'styles'.freeze


    #
    # The name of the object type.
    #
    def self.typename
      return KEYWORD
    end

    #
    # The short name of the object type.
    #
    def self.short_typename
      return KEYWORD_SHORT
    end

    # 
    # Get the name for the form.
    # 
    def name_value
      o = find_child NAME
      o = Gloo::Objs::Alias.resolve_alias( @engine, o )
      return o ? o.value : nil
    end
    
    # 
    # Get the method for the form.
    # 'post' is the default.
    # 
    def method_value
      o = find_child METHOD
      o = Gloo::Objs::Alias.resolve_alias( @engine, o )
      return o.value || METHOD_DEFAULT
    end

    # 
    # Get the action for the form.
    # This is the path to POST to, for example.
    # 
    def action_value
      o = find_child ACTION
      o = Gloo::Objs::Alias.resolve_alias( @engine, o )
      return o ? o.value : nil
    end

    # 
    # Get the cancel path for the form.
    # 
    def cancel_path_value
      o = find_child CANCEL_PATH
      o = Gloo::Objs::Alias.resolve_alias( @engine, o )
      return o ? o.value : nil
    end

    # 
    # Get all the form content, the collection of form fields.
    # 
    def form_content
      o = find_child CONTENT
      o = Gloo::Objs::Alias.resolve_alias( @engine, o )
      return o
    end

    # 
    # Get the styles for the form.
    # Retuns styles in the form of a hash:
    # { 'field_group' => 'form-group mt-3', … }
    # 
    def styles
      style_h = {} 
      o = find_child STYLES
      return style_h unless o
      o = Gloo::Objs::Alias.resolve_alias( @engine, o )

      o.children.each do |c|
        style_h[ c.name ] = c.value
      end

      # puts "styles: #{style_h}"
      return style_h
    end

    # 
    # Get the form styles.
    # Use the name if none is provided.
    # 
    def form_styles
      return @styles['form'] || name_value
    end

    # 
    # Get the submit button styles.
    # 
    def submit_button_styles
      return @styles['submit'] || ''
    end

    # 
    # Get the cancel button styles.
    # 
    def cancel_button_styles
      return @styles['cancel'] || ''
    end


    # ---------------------------------------------------------------------
    #    Children
    # ---------------------------------------------------------------------

    #
    # Does this object have children to add when an object
    # is created in interactive mode?
    # This does not apply during obj load, etc.
    #
    def add_children_on_create?
      return true
    end

    #
    # Add children to this object.
    # This is used by containers to add children needed
    # for default configurations.
    #
    def add_default_children
      fac = @engine.factory

      # Create attributes with ID and Classes
      fac.create_string NAME, '', self
      fac.create_string METHOD, 'post', self
      fac.create_string ACTION, '', self
      fac.create_string CANCEL_PATH, '', self

      fac.create_can CONTENT, self
    end


    # ---------------------------------------------------------------------
    #    Messages
    # ---------------------------------------------------------------------

    #
    # Get a list of message names that this object receives.
    #
    def self.messages
      return super + [ 'render' ]
    end

    #
    # Render the form and all contained fields.
    #
    def msg_render
      content = self.render
      @engine.heap.it.set_to content 
      return content
    end


    # ---------------------------------------------------------------------
    #    Render
    # ---------------------------------------------------------------------

    # 
    # Open the form.
    # 
    def open_form
      name = name_value

      cancel_button = ""
      if cancel_path_value
        cancel_button = <<~HTML
          <a class="#{cancel_button_styles}"
            href="#{cancel_path_value}"> 
            Cancel</a>
        HTML
      end
      return <<~HTML
        <form class='#{form_styles}'
              id='#{name}'
              method='#{method_value}'
              action='#{action_value}'
              accept-charset='UTF-8'>
          <div class="actions">
            <input type="submit" 
              name="commit" 
              value="Save" 
              class="#{submit_button_styles}" 
              data-disable-with="Saving..." />

          #{cancel_button}
          </div>
      HTML
    end

    # 
    # Close the form.
    # 
    def close_form
      return "</form>"
    end

    # 
    # Render the Form as HTML.
    # 
    def render
      @styles = styles
      return open_form + render_content + close_form
    end

    # 
    # Render the element content using the specified render function.
    # This is a recursive function (through one of the other render functions).
    # 
    def render_content 
      fields = ""
      field_can = form_content
      return "" if field_can.nil?

      field_can.children.each do |o|
        o = Gloo::Objs::Alias.resolve_alias( @engine, o )
        if o.class == Field
          fields << o.render( @styles )
        elsif o.class == Element
          fields << o.render_html
        elsif o
          data = render_thing o
          ( fields << data ) if data 
        end
      end

      return fields
    end

    #
    # Render a string or other object.
    #
    def render_thing e
      begin
        return e.render( 'render_html' )
      rescue => e
        @engine.log_exception e
        return ''
      end
    end

    # ---------------------------------------------------------------------
    #    Object Documentation
    # ---------------------------------------------------------------------

    #
    # Get the object's documentation data.
    #
    def self.doc_data
      {
        :name => KEYWORD,
        :shortcut => KEYWORD_SHORT,
        :description => 'An HTML form. Contains a collection of form fields.',
        :children => [
          'name (string) — The name of the form, used for both the name and the id of the form element.',
          'action (string) — The URL to which the form is submitted.',
          "method (string) — Optional, default 'post'. The HTTP method used to submit the form.",
          'cancel_path (string) — The URL to which the form is submitted when the cancel button is clicked.',
          'styles (container) — Container of style classes for the form. Children: actions_div, submit, cancel, field_group, field_label, field_control.',
          'content (container) — The collection of form fields. Other elements can also be included here, for formatting or extra buttons.'
        ],
        :messages => [
          'render — Manually render the HTML form. Normally the render is called by the web server when the page containing the element is requested.'
        ],
        :examples => <<~EXAMPLES.strip
          page [can] :
            messages [can] :
              new [page] :

                head [e] :
                  content [can] :
                    title [e] : New Message

                body [e] :
                  content [can] :
                    nav [alias] : shared.nav
                    h2 [e] : New Message
                    f [form] :
                      name [string] : message_form
                      action [string] : /messages
                      method [string] : post
                      cancel_path [string] : /messages
                      styles [alias] : form_styles
                      content [can] :
                        id [field] :
                          type [string] : hidden
                          value [string] : 13
                        message [field] :
                          type [string] : text
                          autofocus [boolean] : true
                          placeholder [string] : the message goes here…
                          …
        EXAMPLES
      }
    end

  end
end
