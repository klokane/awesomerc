-- Standard awesome library
require("awful")
require("awful.autofocus")
require("awful.rules")
-- Theme handling library
require("beautiful")
-- Notification library
require("naughty")

require("vicious")
require("vicious.contrib")

require("eminent");
require("revelation");

-- Load Debian menu entries
require("debian.menu")

-- {{{ Variable definitions
-- Themes define colours, icons, and wallpapers
beautiful.init("/usr/share/awesome/themes/default/theme.lua")

-- This is used later as the default terminal and editor to run.
terminal = "x-terminal-emulator"
browser = "x-www-browser"
editor = os.getenv("EDITOR") or "editor"
editor_cmd = terminal .. " -e " .. editor

-- Default modkey.
-- Usually, Mod4 is the key with a logo between Control and Alt.
-- If you do not like this or do not have such a key,
-- I suggest you to remap Mod4 to another key using xmodmap or other tools.
-- However, you can use another modifier like Mod1, but it may interact with others.
modkey = "Mod4"

-- Table of layouts to cover with awful.layout.inc, order matters.
layouts =
{
    awful.layout.suit.tile,
    awful.layout.suit.tile.left,
    awful.layout.suit.tile.bottom,
    awful.layout.suit.tile.top,
    awful.layout.suit.fair,
    awful.layout.suit.fair.horizontal,
    awful.layout.suit.spiral,
    awful.layout.suit.spiral.dwindle,
    -- awful.layout.suit.max,
    -- awful.layout.suit.max.fullscreen,
    awful.layout.suit.magnifier,
    awful.layout.suit.floating,
}
-- }}}

-- {{{ Tags
-- Define a tag table which hold all screen tags.
tags = {}
for s = 1, screen.count() do
    -- Each screen has its own tag table.
    tags[s] = awful.tag({ 1, 2, 3, 4, 5, 6, 7, 8, 9 }, s, layouts[1])
end
-- }}}

-- {{{ Menu
-- Create a laucher widget and a main menu
myawesomemenu = {
   { "manual", terminal .. " -e man awesome" },
   { "edit config", editor_cmd .. " " .. awful.util.getdir("config") .. "/rc.lua" },
   { "restart", awesome.restart },
   { "quit", awesome.quit }
}

mymainmenu = awful.menu({ items = { { "awesome", myawesomemenu, beautiful.awesome_icon },
                                    { "Debian", debian.menu.Debian_menu.Debian },
                                    { "open terminal", terminal }
                                  }
                        })

mylauncher = awful.widget.launcher({ image = image(beautiful.awesome_icon),
                                     menu = mymainmenu })
-- }}}

-- {{{ Vicious widgets
  memwidget = widget({ type = 'textbox' })
  vicious.cache(vicious.widgets.mem)
  vicious.register(memwidget, vicious.widgets.mem, '[M :$1%]', 3)

  cpuwidget = widget({ type = 'textbox' })
  vicious.cache(vicious.widgets.cpu)
  vicious.register(cpuwidget, vicious.widgets.cpu, '[C :$1%]', 1)

  volwidget = widget({ type = 'textbox' })
  vicious.register(volwidget, vicious.contrib.pulse, 
    function (widget, args) return string.format("[V :%2d%%]", args[1]) end, 11)
  volwidget:buttons(awful.util.table.join(
    awful.button({ }, 1, function () awful.util.spawn("pavucontrol") end),
    awful.button({ }, 4, function () vicious.contrib.pulse.add(-5)  vicious.force({volwidget}) end),
    awful.button({ }, 5, function () vicious.contrib.pulse.add(5) vicious.force({volwidget}) end)
  ))

  batwidget = widget({ type = 'textbox' })
  vicious.cache(vicious.widgets.bat)
  vicious.register(batwidget, vicious.widgets.bat, 
    function(widget, args) 
      local label = string.format("[%s :%2d%%",args[1],args[2]) 
      if args[3] ~= 'N/A' 
      then 
        label = label .. " (" .. args[3] .. ")"
      end
      label = label .. "]";
      return label
    end, 
    61, 'BAT0')


-- }}}

-- {{{ Wibox
-- Create a textclock widget
mytextclock = awful.widget.textclock({ align = "right" })

-- Create a systray
mysystray = widget({ type = "systray" })

-- Create a wibox for each screen and add it
mywibox = {}
mypromptbox = {}
mylayoutbox = {}
mytaglist = {}
mytaglist.buttons = awful.util.table.join(
                    awful.button({ }, 1, awful.tag.viewonly),
                    awful.button({ modkey }, 1, awful.client.movetotag),
                    awful.button({ }, 3, awful.tag.viewtoggle),
                    awful.button({ modkey }, 3, awful.client.toggletag),
                    awful.button({ }, 4, awful.tag.viewnext),
                    awful.button({ }, 5, awful.tag.viewprev)
                    )
mytasklist = {}
mytasklist.buttons = awful.util.table.join(
                     awful.button({ }, 1, function (c)
                                              if not c:isvisible() then
                                                  awful.tag.viewonly(c:tags()[1])
                                              end
                                              client.focus = c
                                              c:raise()
                                          end),
                     awful.button({ }, 3, function ()
                                              if instance then
                                                  instance:hide()
                                                  instance = nil
                                              else
                                                  instance = awful.menu.clients({ width=250 })
                                              end
                                          end),
                     awful.button({ }, 4, function ()
                                              awful.client.focus.byidx(1)
                                              if client.focus then client.focus:raise() end
                                          end),
                     awful.button({ }, 5, function ()
                                              awful.client.focus.byidx(-1)
                                              if client.focus then client.focus:raise() end
                                          end))

for s = 1, screen.count() do
    -- Create a promptbox for each screen
    mypromptbox[s] = awful.widget.prompt({ layout = awful.widget.layout.horizontal.leftright })
    -- Create an imagebox widget which will contains an icon indicating which layout we're using.
    -- We need one layoutbox per screen.
    mylayoutbox[s] = awful.widget.layoutbox(s)
    mylayoutbox[s]:buttons(awful.util.table.join(
                           awful.button({ }, 1, function () awful.layout.inc(layouts, 1) end),
                           awful.button({ }, 3, function () awful.layout.inc(layouts, -1) end),
                           awful.button({ }, 4, function () awful.layout.inc(layouts, 1) end),
                           awful.button({ }, 5, function () awful.layout.inc(layouts, -1) end)))
    -- Create a taglist widget
    mytaglist[s] = awful.widget.taglist(s, awful.widget.taglist.label.all, mytaglist.buttons)

    -- Create a tasklist widget
    mytasklist[s] = awful.widget.tasklist(function(c)
                                              return awful.widget.tasklist.label.currenttags(c, s)
                                          end, mytasklist.buttons)

    -- Create the wibox
    mywibox[s] = awful.wibox({ position = "top", screen = s })
    -- Add widgets to the wibox - order matters
    mywibox[s].widgets = {
        {
            mylauncher,
            mytaglist[s],
            mypromptbox[s],
            layout = awful.widget.layout.horizontal.leftright
        },
        mytextclock,
        mylayoutbox[s],
        s == 1 and mysystray or nil,
	batwidget,
	volwidget,
        memwidget,
        cpuwidget,
        mytasklist[s],
        layout = awful.widget.layout.horizontal.rightleft
    }
end
-- }}}

-- {{{ Mouse bindings
root.buttons(awful.util.table.join(
    awful.button({ }, 3, function () mymainmenu:toggle() end),
    awful.button({ }, 4, awful.tag.viewnext),
    awful.button({ }, 5, awful.tag.viewprev)
))
-- }}}

-- {{{ Key bindings
globalkeys = awful.util.table.join(
    awful.key({ modkey,           }, "Left",   awful.tag.viewprev       ),
    awful.key({ modkey,           }, "Right",  awful.tag.viewnext       ),
    awful.key({ modkey,           }, "Escape", awful.tag.history.restore),

    awful.key({ modkey, "Shift"   }, "Left",   
                function ()
                        local c = client.focus
                        awful.tag.viewidx(-1)
			awful.client.movetotag(awful.tag.selected(),c)
			awful.client.focus.byidx(0,c)
                end),
    awful.key({ modkey, "Shift"   }, "Right", 
                function ()
                        local c = client.focus
                        awful.tag.viewidx(1)
			awful.client.movetotag(awful.tag.selected(),c)
			awful.client.focus.byidx(0,c)
                end),

    -- switch screen
    awful.key({ modkey,           }, "Up", function () awful.screen.focus_relative( 1) end),
    awful.key({ modkey,           }, "Down", function () awful.screen.focus_relative(-1) end),

    awful.key({ modkey,           }, "j",
        function ()
            awful.client.focus.byidx( 1)
            if client.focus then client.focus:raise() end
        end),
    awful.key({ modkey,           }, "k",
        function ()
            awful.client.focus.byidx(-1)
            if client.focus then client.focus:raise() end
        end),
    awful.key({ modkey,           }, "w", function () mymainmenu:show(true)        end),

    -- Layout manipulation
    awful.key({ modkey, "Shift"   }, "j", function () awful.client.swap.byidx(  1)    end),
    awful.key({ modkey, "Shift"   }, "k", function () awful.client.swap.byidx( -1)    end),
    awful.key({ modkey,           }, "u", awful.client.urgent.jumpto),
    awful.key({ modkey,           }, "Tab",
        function ()
            awful.client.focus.history.previous()
            if client.focus then
                client.focus:raise()
            end
        end),

    -- Standard program
    awful.key({ modkey,           }, "Return", function () awful.util.spawn(terminal) end),
    awful.key({ modkey, "Control" }, "r", awesome.restart),
    awful.key({ modkey, "Shift"   }, "q", awesome.quit),

    awful.key({ modkey,           }, "l",     function () awful.tag.incmwfact( 0.05)    end),
    awful.key({ modkey,           }, "h",     function () awful.tag.incmwfact(-0.05)    end),
    awful.key({ modkey, "Shift"   }, "h",     function () awful.tag.incnmaster( 1)      end),
    awful.key({ modkey, "Shift"   }, "l",     function () awful.tag.incnmaster(-1)      end),
    awful.key({ modkey, "Control" }, "h",     function () awful.tag.incncol( 1)         end),
    awful.key({ modkey, "Control" }, "l",     function () awful.tag.incncol(-1)         end),
    awful.key({ modkey,           }, "space", function () awful.layout.inc(layouts,  1) end),
    awful.key({ modkey, "Shift"   }, "space", function () awful.layout.inc(layouts, -1) end),

    -- Prompt
    awful.key({ modkey },            "r",     function () mypromptbox[mouse.screen]:run() end),

    awful.key({ modkey }, "x",
              function ()
                  awful.prompt.run({ prompt = "Run Lua code: " },
                  mypromptbox[mouse.screen].widget,
                  awful.util.eval, nil,
                  awful.util.getdir("cache") .. "/history_eval")
              end),

-- multimedia keys
    awful.key({}, "XF86HomePage", 
	function () 
		awful.util.spawn(browser) 
	end),
    awful.key({ "Shift" }, "XF86HomePage", 
	function () 
		awful.util.spawn(browser .. ' --incognito') 
	end),
    awful.key({}, "XF86AudioLowerVolume", function () awful.util.spawn("amixer -c 0 -q sset Master 5%-") vicious.force({volwidget}) end),
    awful.key({}, "XF86AudioRaiseVolume", function () awful.util.spawn("amixer -c 0 -q sset Master 5%+") vicious.force({volwidget}) end),
    awful.key({}, "XF86AudioMute", function () awful.util.spawn("amixer -q sset Master toggle") vicious.force({volwidget}) end),

    awful.key({}, "Print", function () awful.util.spawn("gnome-screenshot") end),

    awful.key({ modkey,           }, "e",   revelation       ),

    awful.key({ modkey, "Shift" }, "t", function () awful.util.spawn("hamster-time-tracker") end)
    )

clientkeys = awful.util.table.join(
    awful.key({ modkey,           }, "f",      function (c) c.fullscreen = not c.fullscreen  end),
    awful.key({ modkey, "Shift"   }, "c",      function (c) c:kill()                         end),
    awful.key({ modkey, "Control" }, "space",  awful.client.floating.toggle                     ),
    awful.key({ modkey, "Control" }, "Return", 
	function (c) 
-- IDEA: swap window with master and swap master/slave flags
		c:swap(awful.client.getmaster()) 
	end),
    awful.key({ modkey,           }, "o",      awful.client.movetoscreen                        ),
    awful.key({ modkey, "Shift"   }, "r",      function (c) c:redraw()                       end),
    awful.key({ modkey,           }, "n",      function (c) c.minimized = not c.minimized    end),
    awful.key({ modkey, "Shift"   }, "t",      function (c) c.ontop = not c.ontop            end),
    awful.key({ modkey,           }, "m",
        function (c)
            c.maximized_horizontal = not c.maximized_horizontal
            c.maximized_vertical   = not c.maximized_vertical
        end),

    awful.key({modkey, },    "i",        
      function (c)
	print("==Window info: ==")
	if c.window then print("Window: " .. c.window) end
	if c.name then print("Name: " .. c.name) end
	if c.type then print("Type: " .. c.type) end
	if c.class then print("Class: " .. c.class) end
	if c.pid then print("PID: " .. c.pid) end
	if c.role then print("Role:" .. c.role) end
	if c.group then print("Group win:" .. c.group) end
    --    local geom = c:geometry()

    --    local t = ""
    --    if c.class then t = t .. "Class: " .. c.class .. "\n" end
    --    if c.instance then t = t .. "Instance: " .. c.instance .. "\n" end
    --    if c.role then t = t .. "Role: " .. c.role .. "\n" end
    --    if c.name then t = t .. "Name: " .. c.name .. "\n" end
    --    if c.type then t = t .. "Type: " .. c.type .. "\n" end
    --    if geom.width and geom.height and geom.x and geom.y then
    --      t = t .. "Dimensions: " .. "x:" .. geom.x .. " y:" .. geom.y .. " w:" .. geom.width .. " h:" .. geom.height
    --    end
    --    t = t .. "\nAttrs: "
    --    -- if c.focusable then t = t .. "focusable, " end
    --    -- if c.modal then t = t .. "modal, " end
    --    -- if c.sticky then t = t .. "sticky, " end
    --    -- if c.ontop then t = t .. "ontop, " end
    --    if awful.client.dockable.get(c) then t = t .. "dockable, " end
    --    if c.fullscreen then t = t .. "fullscreen, " end

    --    naughty.notify({ text = t, timeout = 10 })
    end)

)

-- Compute the maximum number of digit we need, limited to 9
keynumber = 0
for s = 1, screen.count() do
   keynumber = math.min(9, math.max(#tags[s], keynumber));
end

-- Bind all key numbers to tags.
-- Be careful: we use keycodes to make it works on any keyboard layout.
-- This should map on the top row of your keyboard, usually 1 to 9.
for i = 1, keynumber do
    globalkeys = awful.util.table.join(globalkeys,
        awful.key({ modkey }, "#" .. i + 9,
                  function ()
                        local screen = mouse.screen
                        if tags[screen][i] then
                            awful.tag.viewonly(tags[screen][i])
                        end
                  end),
        awful.key({ modkey, "Control" }, "#" .. i + 9,
                  function ()
                      local screen = mouse.screen
                      if tags[screen][i] then
                          awful.tag.viewtoggle(tags[screen][i])
                      end
                  end),
        awful.key({ modkey, "Shift" }, "#" .. i + 9,
                  function ()
                      if client.focus and tags[client.focus.screen][i] then
                          awful.client.movetotag(tags[client.focus.screen][i])
                      end
                  end),
        awful.key({ modkey, "Control", "Shift" }, "#" .. i + 9,
                  function ()
                      if client.focus and tags[client.focus.screen][i] then
                          awful.client.toggletag(tags[client.focus.screen][i])
                      end
                  end))
end

clientbuttons = awful.util.table.join(
    awful.button({ }, 1, function (c) client.focus = c; c:raise() end),
    awful.button({ modkey }, 1, awful.mouse.client.move),
    awful.button({ modkey }, 3, awful.mouse.client.resize))

-- Set keys
root.keys(globalkeys)
-- }}}

-- {{{ Rules
awful.rules.rules = {
    -- All clients will match this rule.
    { rule = { },
      properties = { border_width = beautiful.border_width,
                     border_color = beautiful.border_normal,
                     focus = true,
                     keys = clientkeys,
                     buttons = clientbuttons,
                     size_hints_honor = false } },
    { rule = { class = "MPlayer" },
      properties = { floating = true } },
    { rule = { class = "pinentry" },
      properties = { floating = true } },

    { rule = { role = "gimp-toolbox" },
      properties = { floating = true,  
                     maximized_horizontal = true,
                     size_hints_honor = false },
      callback = function(c) 
        local s = c.screen
        local workarea = screen[s].workarea
        local strutwidth = 212
        c:struts({ left = strutwidth })
        c:geometry( { x = 0, width = strutwidth, y = workarea.y, height = workarea.height } )
      end
    },

    { rule = { role = "gimp-dock" },
      properties = { floating = true,  
                     maximized_horizontal = true,
                     size_hints_honor = false },
      callback = function(c) 
        local s = c.screen
        local workarea = screen[s].workarea
        local strutwidth = 212
        c:struts({ right = strutwidth })
        c:geometry( { x = workarea.width-strutwidth, width = strutwidth, y = workarea.y, height = workarea.height } )
      end
    },
    
    { rule = { class = "Revelation", type = "dialog" },
      properties = { floating = true,  } },
    { rule = { class = "Revelation", type = "normal" },
      properties = { floating = true,  size_hints_honor = false },
      callback = function(c) 
        local s = c.screen
        local workarea = screen[s].workarea
        local strutwidth = 350
        c:struts({ left = strutwidth })
        c:geometry( { x = 0, width = strutwidth, y = workarea.y, height = workarea.height } )
        awful.tag.setnmaster(0,awful.tag.selected())
      end },

    { rule = { class = "Rhythmbox" },
      properties = { sticky = true, skip_taskbar = true, floating = true } },
    { rule = { class = "Skype" },
      properties = { floating = true } }
    -- Set Firefox to always map on tags number 2 of screen 1.
    -- { rule = { class = "Firefox" },
    --   properties = { tag = tags[1][2] } },
}
-- }}}

-- {{{ Signals
-- Signal function to execute when a new client appears.
client.add_signal("manage", function (c, startup)
    -- Add a titlebar
    -- awful.titlebar.add(c, { modkey = modkey })

    -- Enable sloppy focus
    c:add_signal("mouse::enter", function(c)
        if awful.layout.get(c.screen) ~= awful.layout.suit.magnifier
            and awful.client.focus.filter(c) then
            client.focus = c
        end
    end)

    if not startup then
        -- Set the windows at the slave,
        -- i.e. put it at the end of others instead of setting it master.
        awful.client.setslave(c)

        -- Put windows in a smart way, only if they does not set an initial position.
        if not c.size_hints.user_position and not c.size_hints.program_position then
            awful.placement.no_overlap(c)
            awful.placement.no_offscreen(c)
        end
    end
end)

-- client.add_signal("focus", function(c) c.border_color = beautiful.border_focus end)
client.add_signal("focus", function(c) c.border_color = "#2B8E00" end)
client.add_signal("unfocus", function(c) c.border_color = beautiful.border_normal end)

-- }}}


-- {{{ autostart
-- os.execute("setxkbmap us,cz_qwerty -option grp:switch,grp:shifts_toggle,grp_led:scroll&");
-- os.execute("nm-applet &")
-- os.execute("gnome-volume-control-applet &");
-- os.execute("$HOME/.xprofile &");
-- os.execute("$HOME/bin/dex -a");
-- awful.util.spawn_with_shell("$HOME/bin/dex -a");
-- }}}
