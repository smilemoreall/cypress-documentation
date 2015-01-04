@App.module "TestCommandsApp.List", (List, App, Backbone, Marionette, $, _) ->

  class List.Command extends App.Views.ItemView
    template: "test_commands/list/_default"
    # getTemplate: ->
    #   switch @model.get("type")
    #     when "xhr"          then "test_commands/list/_xhr"
    #     when "dom"          then "test_commands/list/_dom"
    #     when "assertion"    then "test_commands/list/_assertion"
    #     when "server"       then "test_commands/list/_server"
    #     when "spy"          then "test_commands/list/_spy"
    #     when "stub"         then "test_commands/list/_stub"
    #     when "visit"        then "test_commands/list/_visit"
    #     when "localStorage" then "test_commands/list/_local_storage"
    #     else
    #       throw new Error("Command .type did not match any template")

    ui:
      wrapper:  ".command-wrapper"
      method:   ".command-method"
      # pause:    ".fa-pause"
      revert:   ".fa-search"

    modelEvents:
      "change:response"  : "render"
      "change:chosen"    : "chosenChanged"
      "change:highlight" : "highlightChanged"

    triggers:
      "click @ui.pause"   : "pause:clicked"
      "click @ui.revert"  : "revert:clicked"
      "mouseenter"        : "command:mouseenter"
      "mouseleave"        : "command:mouseleave"

    events:
      "click"               : "clicked"

    onShow: ->
      @$el
        .addClass("command-type-#{@model.get("type")}")
        .addClass("command-name-#{@model.displayName()}")

      # switch @model.get("type")
      #   when "dom"
      #     ## quick hack to get sub types
      #     @$el.addClass "command-type-dom-action" if not @model.isParent()

      #   when "assertion"
      #     klass = if @model.get("passed") then "passed" else "failed"
      #     @$el.addClass "command-assertion-#{klass}"

      @ui.method.css "padding-left", @model.get("indent")

      if @model.hasParent()
        @ui.wrapper.addClass "command-child"
      else
        @$el.addClass "command-parent"

      @$el.addClass "command-cloned" if @model.isCloned()

      @model.triggerCommandCallback("onRender", @$el)

    clicked: (e) ->
      e.stopPropagation()

      @displayConsoleMessage()

      console.clear?()

      @model.getConsoleDisplay (obj) ->
        console.log obj...

    displayConsoleMessage: ->
      width  = @$el.outerWidth()
      offset = @$el.offset()

      div = $("<div>", class: "command-console-message")
      div.text("Printed output to your console!")

      ## center this guy in the middle of our command
      div.appendTo($("body"))
        .css
          top: offset.top
          left: offset.left
          marginLeft: (width / 2) - (div.innerWidth() / 2)
      div
        .fadeIn(180)
          .delay(120)
            .fadeOut 300, -> $(@).remove()

    chosenChanged: (model, value, options) ->
      @$el.toggleClass "active", value

    highlightChanged: (model, value, options) ->
      @$el.toggleClass "highlight", value

  class List.Hook extends App.Views.CompositeView
    template: "test_commands/list/_hook"
    tagName: "li"
    className: "hook-item"
    childView: List.Command
    childViewContainer: "ul"

    ui:
      "commands" : ".commands-container"
      "caret"    : "i.fa-caret-down"
      "ellipsis" : "i.fa-ellipsis-h"
      "failed"   : ".hook-failed"

    modelEvents:
      "change:visible" : "visibleChanged"
      "change:failed"  : "failedChanged"

    events:
      "click .hook-name" : "hookClicked"

    initialize: ->
      @collection = @model.get("commands")

    hookClicked: (e) ->
      @model.toggle()
      e.preventDefault()
      e.stopPropagation()

    visibleChanged: (model, value, options) ->
      @ui.commands.toggleClass "hidden", !value
      @changeIconDirection(!value)
      @displayEllipsis(!value)

    changeIconDirection: (bool) ->
      klass = if bool then "right" else "down"
      @ui.caret.removeClass().addClass("fa fa-caret-#{klass}")

    displayEllipsis: (bool) ->
      @ui.ellipsis.toggleClass "hidden", !bool

    failedChanged: (model, bool, options) ->
      @ui.failed.toggleClass "hidden", !bool

  class List.Empty extends App.Views.ItemView
    template: "test_commands/list/_empty"

  class List.Hooks extends App.Views.CollectionView
    tagName: "ul"
    className: "hooks-container"
    childView: List.Hook
    emptyView: List.Empty

    isEmpty: -> @renderEmpty