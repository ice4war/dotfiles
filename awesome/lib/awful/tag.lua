---------------------------------------------------------------------------
--- Useful functions for tag manipulation.
--
-- @author Julien Danjou &lt;julien@danjou.info&gt;
-- @copyright 2008 Julien Danjou
-- @module tag
---------------------------------------------------------------------------

-- Grab environment we need
local gdebug = require("gears.debug")
local ascreen = require("awful.screen")
local beautiful = require("beautiful")
local gmath = require("gears.math")
local object = require("gears.object")
local timer = require("gears.timer")
local gtable = require("gears.table")
local alayout = nil
local pairs = pairs
local ipairs = ipairs
local table = table
local setmetatable = setmetatable
local capi =
{
    tag = tag,
    screen = screen,
    mouse = mouse,
    client = client,
    root = root
}

local function get_screen(s)
    return s and capi.screen[s]
end

local tag = {object = {},  mt = {} }

-- Private data
local data = {}
data.history = {}

-- History functions
tag.history = {}
tag.history.limit = 20

-- Default values
local defaults = {}

-- The gap between clients (in points).
defaults.gap                 = 0

-- The default gap_count.
defaults.gap_single_client   = true

-- The default master fill policy.
defaults.master_fill_policy  = "expand"

-- The default master width factor.
defaults.master_width_factor = 0.5

-- The default master count.
defaults.master_count        = 1

-- The default column count.
defaults.column_count        = 1

-- screen.tags depend on index, it cannot be used by awful.tag
local function raw_tags(scr)
    local tmp_tags = {}
    for _, t in ipairs(root.tags()) do
        if get_screen(t.screen) == scr then
            table.insert(tmp_tags, t)
        end
    end

    return tmp_tags
end

local function custom_layouts(self)
    local cls = tag.getproperty(self, "_custom_layouts")

    if not cls then
        cls = {}
        tag.setproperty(self, "_custom_layouts", cls)
    end

    return cls
end

-- Update the "user visible" list of layouts. If `from` and `to` are not the
-- same, then `from` will be replaced. This is necessary for either the layouts
-- defined as a function (called "template" below) and object oriented, stateful
-- layouts where the original entry is only a constructor.
local function update_layouts(self, from, to)
    if not to then return end

    alayout = alayout or require("awful.layout")
    local override = tag.getproperty(self, "_layouts")

    local pos = from and gtable.hasitem(override or {}, from) or nil

    -- There is an override and the layout template is part of it, replace by
    -- the instance.
    if override and pos and from ~= to then
        assert(type(pos) == 'number')
        override[pos] = to
        self:emit_signal("property::layouts")
        return
    end

    -- Only add to the custom_layouts and preserve the ability to globally
    -- set the layouts.
    if override and not pos then
        table.insert(override, to)
        self:emit_signal("property::layouts")
        return
    end

    pos = from and gtable.hasitem(alayout.layouts, from) or nil

    local cls = custom_layouts(self)

    -- The new layout is part of the global layouts. Fork the list.
    if pos and from ~= to then
        local cloned = gtable.clone(alayout.layouts, false)
        cloned[pos] = to
        gtable.merge(cloned, cls)
        self.layouts = cloned
        return
    end

    if pos then return end

    if gtable.hasitem(cls, to) then return end

    -- This layout is unknown, add it to the custom list
    table.insert(cls, to)
    self:emit_signal("property::layouts")
end

--- The number of elements kept in the history.
-- @tfield integer awful.tag.history.limit
-- @tparam[opt=20] integer limit

--- The tag index.
--
-- 
--
--<object class=&#34img-object&#34 data=&#34../images/AUTOGEN_sequences_tag_index.svg&#34 alt=&#34Usage example&#34 type=&#34image/svg+xml&#34></object>
--
-- 
--     -- Calling awful.tag.new
--     awful.tag({ &#34one&#34, &#34two&#34, &#34three&#34, &#34four&#34 }, screen[1])
--  
--     -- Send the first tag to index 3.
--     screen[1].tags[1].index = 3
--  
--     -- Send the first tag to index 3.
--     screen[1].tags[4].index = 1
--
-- The index is the position as shown in the `awful.widget.taglist`.
--
-- @property index
-- @tparam integer index
-- @propertydefault This is based on the current list of `t.screen:tags()`.
-- @negativeallowed false
-- @propemits false false

function tag.object.set_index(self, idx)
    local scr = get_screen(tag.getproperty(self, "screen"))

    -- screen.tags cannot be used as it depend on index
    local tmp_tags = raw_tags(scr)

    -- sort the tags by index
    table.sort(tmp_tags, function(a, b)
        local ia, ib = tag.getproperty(a, "index"), tag.getproperty(b, "index")
        return (ia or math.huge) < (ib or math.huge)
    end)

    if (not idx) or (idx < 1) or (idx > #tmp_tags) then
        return
    end

    local rm_index = nil

    for i, t in ipairs(tmp_tags) do
        if t == self then
            table.remove(tmp_tags, i)
            rm_index = i
            break
        end
    end

    table.insert(tmp_tags, idx, self)
    for i = idx < rm_index and idx or rm_index, #tmp_tags do
        local tmp_tag = tmp_tags[i]
        tag.object.set_screen(tmp_tag, scr)
        tag.setproperty(tmp_tag, "index", i)
    end
end

function tag.object.get_index(query_tag)

    local idx = tag.getproperty(query_tag, "index")

    if idx then return idx end

    -- Get an unordered list of tags
    local tags = raw_tags(query_tag.screen)

    -- Too bad, lets compute it
    for i, t in ipairs(tags) do
        if t == query_tag then
            tag.setproperty(t, "index", i)
            return i
        end
    end
end

--- Move a tag to an absolute position in the `screen[]:tags()` table.
-- @deprecated awful.tag.move
-- @tparam integer new_index Integer absolute position in the table to insert.
-- @tparam[opt=awful.screen.focused().selected_tag] tag target_tag The tag that should be moved.
-- @see index
function tag.move(new_index, target_tag)
    gdebug.deprecate("Use t.index = new_index instead of awful.tag.move", {deprecated_in=4})

    target_tag = target_tag or ascreen.focused().selected_tag
    tag.object.set_index(target_tag, new_index)
end

--- Swap 2 tags.
--
-- 
--
--<object class=&#34img-object&#34 data=&#34../images/AUTOGEN_sequences_tag_swap.svg&#34 alt=&#34Usage example&#34 type=&#34image/svg+xml&#34></object>
--
-- 
--     -- Calling awful.tag.new
--     awful.tag({ &#34one&#34, &#34two&#34, &#34three&#34, &#34four&#34 }, screen[1])
--      
--     screen[1].tags[2]:view_only()
--  
--     -- Swap tag 2 with tag 4.
--     screen[1].tags[2]:swap(screen[1].tags[4])
--
-- @method swap
-- @tparam tag tag2 The second tag
-- @noreturn
-- @see client.swap
function tag.object.swap(self, tag2)
    local idx1, idx2 = tag.object.get_index(self), tag.object.get_index(tag2)
    local scr2, scr1 = tag.getproperty(tag2, "screen"), tag.getproperty(self, "screen")

    -- If they are on the same screen, avoid recomputing the whole table
    -- for nothing.
    if scr1 == scr2 then
        tag.setproperty(self, "index", idx2)
        tag.setproperty(tag2, "index", idx1)
    else
        tag.object.set_screen(tag2, scr1)
        tag.object.set_index (tag2, idx1)
        tag.object.set_screen(self, scr2)
        tag.object.set_index (self, idx2)
    end
end

--- Swap 2 tags
-- @deprecated awful.tag.swap
-- @see tag.swap
-- @tparam tag tag1 The first tag
-- @tparam tag tag2 The second tag
function tag.swap(tag1, tag2)
    gdebug.deprecate("Use t:swap(tag2) instead of awful.tag.swap", {deprecated_in=4})

    tag.object.swap(tag1, tag2)
end

--- Add a tag.
--
-- This function allow to create tags from a set of properties:
--
--    local t = awful.tag.add("my new tag", {
--        screen = screen.primary,
--        layout = awful.layout.suit.max,
--    })
--
-- @constructorfct awful.tag.add
-- @tparam string name The tag name, a string
-- @tparam[opt=nil] table|nil props The tags initial properties, a table
-- @treturn tag The created tag.
-- @see tag.delete
function tag.add(name, props)
    local properties = props or {}

    -- Be sure to set the screen before the tag is activated to avoid function
    -- connected to property::activated to be called without a valid tag.
    -- set properties cannot be used as this has to be set before the first
    -- signal is sent
    properties.screen = get_screen(properties.screen or ascreen.focused())
    -- Index is also required
    properties.index = properties.index or #raw_tags(properties.screen)+1

    local newtag = capi.tag{ name = name }

    -- Start with a fresh property table to avoid collisions with unsupported data
    newtag._private.awful_tag_properties = {screen=properties.screen, index=properties.index}

    newtag.activated = true

    for k, v in pairs(properties) do
        -- `rawget` doesn't work on userdata, `:clients()` is the only relevant
        -- entry.
        if k == "clients" or tag.object[k] then
            newtag[k](newtag, v)
        else
            newtag[k] = v
        end
    end

    return newtag
end

--- Create a set of tags and attach it to a screen.
--
-- This is what's performed by the default config:
--
-- 
--
--<object class=&#34img-object&#34 data=&#34../images/AUTOGEN_sequences_tag_default_config.svg&#34 alt=&#34Usage example&#34 type=&#34image/svg+xml&#34></object>
--
-- 
--     -- Calling awful.tag.new
--     awful.tag({ &#341&#34, &#342&#34, &#343&#34, &#344&#34, &#345&#34, &#346&#34, &#347&#34, &#348&#34, &#349&#34 }, screen[1], awful.layout.layouts[1])
--
-- It is also possible to set multiple layouts:
--
-- 
--
--<object class=&#34img-object&#34 data=&#34../images/AUTOGEN_sequences_tag_new_with_layouts.svg&#34 alt=&#34Usage example&#34 type=&#34image/svg+xml&#34></object>
--
-- 
--     local some_layouts = {
--         awful.layout.suit.fair,
--         awful.layout.suit.spiral,
--         awful.layout.suit.spiral.dwindle,
--         awful.layout.suit.magnifier,
--         awful.layout.suit.corner.nw,
--     }
--      
--     -- Calling awful.tag.new
--     awful.tag({ &#34one&#34, &#34two&#34, &#34three&#34, &#34four&#34, &#34five&#34 }, screen[1], some_layouts)
--  
--     -- Add some clients
--     for _, t in ipairs(screen[1].tags) do
--         for _ = 1, 5 do
--             awful.spawn(&#34xterm&#34, {tag = t})
--         end
--     end
--
-- @staticfct awful.tag.new
-- @tparam table names The tag name, in a table
-- @tparam[opt=1] screen|number screen The tag screen.
-- @tparam table layout The layout or layout table to set for this tags by default.
-- @treturn table A table with all created tags.
function tag.new(names, screen, layout)
    screen = get_screen(screen or 1)
    -- True if `layout` should be used as the layout of each created tag
    local have_single_layout = (not layout) or (type(layout) == 'function')
                                or (layout.arrange and layout.name)
    local tags = {}
    for id, name in ipairs(names) do
        local l = layout
        if not have_single_layout then
            l = layout[id] or layout[1]
        end
        table.insert(tags, id, tag.add(name, {screen = screen, layout = l}))
        -- Select the first tag.
        if id == 1 then
            tags[id].selected = true
        end
    end

    return tags
end

--- Find a suitable fallback tag.
-- @staticfct awful.tag.find_fallback
-- @tparam[opt=awful.screen.focused()] screen screen The screen to look for a tag on.
-- @tparam[opt=nil] table|nil invalids A table of tags considered unacceptable.
-- @treturn tag|nil Returns a fallback tag if one was found, otherwise `nil`.
function tag.find_fallback(screen, invalids)
    local scr = screen or ascreen.focused()
    local t = invalids or scr.selected_tags

    for _, v in pairs(scr.tags) do
        if not gtable.hasitem(t, v) then return v end
    end
end

--- Emitted when all clients are removed from the tag.
-- @signal cleared
-- @see clear

--- Remove all tagged clients.
--
-- 
--
--<object class=&#34img-object&#34 data=&#34../images/AUTOGEN_sequences_tag_clear.svg&#34 alt=&#34Usage example&#34 type=&#34image/svg+xml&#34></object>
--
-- 
--     -- Calling awful.tag.new
--     awful.tag({ &#34one&#34, &#34two&#34 }, screen[1], some_layouts)
--  
--     -- Call :clear() on the first tag.
--     screen[1].tags[1]:clear{}
--
-- @method clear
-- @tparam table args The arguments.
-- @tparam tag args.fallback_tag A fallback tag.
-- @tparam[opt=false] boolean args.allow_untagged Allow the untagged clients to remain untagged.
-- @noreturn
-- @emits cleared After all clients have been untagged.
-- @emits untagged For each currently tagged clients.
-- @emitstparam untagged client c The untagged client.
function tag.object.clear(self, args)
    args = args or {}

    local clients = self:clients()

    -- Clear
    self:clients({})

    if #clients > 0 and not args.allow_untagged then
        local target_scr = get_screen(tag.getproperty(self, "screen"))
        local fallback_tag = args.fallback_tag or tag.find_fallback(target_scr, {self})

        if not fallback_tag then return end

        for _, c in ipairs(clients) do
            if #c:tags() == 0 then
                c:tags({fallback_tag})
            end
        end
    end

    self:emit_signal("cleared")
end

--- Delete a tag.
--
-- To delete the current tag:
--
-- 
--
--<object class=&#34img-object&#34 data=&#34../images/AUTOGEN_sequences_tag_delete.svg&#34 alt=&#34Usage example&#34 type=&#34image/svg+xml&#34></object>
--
-- 
--     -- Calling awful.tag.new
--     awful.tag({ &#34one&#34, &#34two&#34, &#34three&#34, &#34four&#34 }, screen[1])
--      
--     screen[1].tags[2]:view_only()
--  
--     -- Delete the selected tag.
--     mouse.screen.selected_tag:delete()
--
-- @method delete
-- @see awful.tag.add
-- @see awful.tag.find_fallback
-- @tparam[opt=awful.tag.find_fallback()] tag fallback_tag Tag to assign
--  stickied tags to.
-- @tparam[opt=false] boolean force Move even non-sticky clients to the fallback
-- tag.
-- @treturn boolean Returns true if the tag is successfully deleted.
-- If there are no clients exclusively on this tag then delete it. Any
-- stickied clients are assigned to the optional 'fallback_tag'.
-- If after deleting the tag there is no selected tag, try and restore from
-- history or select the first tag on the screen.
function tag.object.delete(self, fallback_tag, force)
    -- abort if the taf isn't currently activated
    if not self.activated then return false end

    local target_scr = get_screen(tag.getproperty(self, "screen"))
    local tags       = target_scr.tags
    local idx        = tag.object.get_index(self)
    local ntags      = #tags

    -- We can't use the target tag as a fallback.
    if fallback_tag == self then return false end

    -- No fallback_tag provided, try and get one.
    if fallback_tag == nil then
        fallback_tag = tag.find_fallback(target_scr, {self})
    end

    -- Abort if we would have un-tagged clients.
    local clients = self:clients()
    if #clients > 0 and fallback_tag == nil then return false end

    -- Move the clients we can off of this tag.
    for _, c in pairs(clients) do
        local nb_tags = #c:tags()

        -- If a client has only this tag, or stickied clients with
        -- nowhere to go, abort.
        if (not c.sticky and nb_tags == 1 and not force) then
            return
        -- If a client has multiple tags, then do not move it to fallback
        elseif nb_tags < 2 then
            c:tags({fallback_tag})
        end
    end

    -- delete the tag
    tag.setproperty(self, "screen", nil)
    self.activated = false

    -- Update all indexes
    for i=idx+1, #tags do
        tag.setproperty(tags[i], "index", i-1)
    end

    -- If no tags are visible (and we did not delete the lasttag), try and
    -- view one. The > 1 is because ntags is no longer synchronized with the
    -- current count.
    if target_scr.selected_tag == nil and ntags > 1 then
        tag.history.restore(target_scr, 1)
        if target_scr.selected_tag == nil then
            local other_tag = tags[tags[1] == self and 2 or 1]
            if other_tag then
                other_tag.selected = true
            end
        end
    end

    return true
end

--- Delete a tag.
-- @deprecated awful.tag.delete
-- @see tag.delete
-- @tparam[opt=mouse.screen.selected_tag] tag target_tag Optional tag object to delete.
-- @tparam[opt] tag|nil fallback_tag Tag to assign stickied tags to.
-- @treturn boolean Returns true if the tag is successfully deleted, nil otherwise.
-- If there are no clients exclusively on this tag then delete it. Any
-- stickied clients are assigned to the optional 'fallback_tag'.
-- If after deleting the tag there is no selected tag, try and restore from
-- history or select the first tag on the screen.
function tag.delete(target_tag, fallback_tag)
    gdebug.deprecate("Use t:delete(fallback_tag) instead of awful.tag.delete", {deprecated_in=4})

    return tag.object.delete(target_tag, fallback_tag)
end

--- Update the tag history.
-- @staticfct awful.tag.history.update
-- @tparam screen obj Screen object.
-- @noreturn
function tag.history.update(obj)
    local s = get_screen(obj)
    local curtags = s.selected_tags
    -- create history table
    if not data.history[s] then
        data.history[s] = {}
    else
        if data.history[s].current then
            -- Check that the list is not identical
            local identical = #data.history[s].current == #curtags
            if identical then
                for idx, _tag in ipairs(data.history[s].current) do
                    if curtags[idx] ~= _tag then
                        identical = false
                        break
                    end
                end
            end

            -- Do not update history the table are identical
            if identical then return end
        end

        -- Limit history
        if #data.history[s] >= tag.history.limit then
            for i = tag.history.limit, #data.history[s] do
                data.history[s][i] = nil
            end
        end
    end

    -- store previously selected tags in the history table
    table.insert(data.history[s], 1, data.history[s].current)
    data.history[s].previous = data.history[s][1]
    -- store currently selected tags
    data.history[s].current = setmetatable(curtags, { __mode = 'v' })
end

--- Revert tag history.
-- @staticfct awful.tag.history.restore
-- @noreturn
-- @tparam screen screen The screen.
-- @tparam number idx Index in history. Defaults to "previous" which is a special index
-- toggling between last two selected sets of tags. Number (eg 1) will go back
-- to the given index in history.
function tag.history.restore(screen, idx)
    local s = get_screen(screen or ascreen.focused())
    local i = idx or "previous"
    local sel = s.selected_tags
    -- do nothing if history empty
    if not data.history[s] or not data.history[s][i] then return end
    -- if all tags been deleted, try next entry
    if #data.history[s][i] == 0 then
        if i == "previous" then i = 0 end
        tag.history.restore(s, i + 1)
        return
    end
    -- deselect all tags
    tag.viewnone(s)
    -- select tags from the history entry
    for _, t in ipairs(data.history[s][i]) do
        if t.activated and t.screen then
            t.selected = true
        end
    end
    -- update currently selected tags table
    data.history[s].current = data.history[s][i]
    -- store previously selected tags
    data.history[s].previous = setmetatable(sel, { __mode = 'v' })
    -- remove the reverted history entry
    if i ~= "previous" then table.remove(data.history[s], i) end

    s:emit_signal("tag::history::update")
end

--- Get a list of all tags on a screen
-- @deprecated awful.tag.gettags
-- @tparam screen s Screen
-- @treturn table A table with all available tags
-- @see screen.tags
function tag.gettags(s)
    gdebug.deprecate("Use s.tags instead of awful.tag.gettags", {deprecated_in=4})

    s = get_screen(s)

    return s and s.tags or {}
end

--- Find a tag by name.
-- @tparam screen s The screen of the tag
-- @tparam string name The name of the tag
-- @treturn tag|nil The tag found, or `nil`
-- @staticfct awful.tag.find_by_name
-- @usage -- For the current screen
-- local t = awful.tag.find_by_name(awful.screen.focused(), "name")
--
-- -- For a screen index
-- local t = awful.tag.find_by_name(screen[1], "name")
--
-- -- For all screens
-- local t = awful.tag.find_by_name(nil, "name")
function tag.find_by_name(s, name)
    --TODO v5: swap the arguments and make screen [opt]
    local tags = s and s.tags or root.tags()
    for _, t in ipairs(tags) do
        if name == t.name then
            return t
        end
    end
end

--- The tag screen.
--
-- @property screen
-- @tparam[opt=awful.screen.focused()] screen screen
-- @propemits false false
-- @see screen

function tag.object.set_screen(t, s)

    s = get_screen(s or ascreen.focused())
    local sel = t.selected
    local old_screen = get_screen(tag.getproperty(t, "screen"))

    if s == old_screen then return end

    -- Keeping the old index make very little sense when changing screen
    tag.setproperty(t, "index", nil)

    -- Change the screen
    tag.setproperty(t, "screen", s)
    if s then
        tag.setproperty(t, "index", #s:get_tags(true))
    end

    -- Make sure the client's screen matches its tags
    for _,c in ipairs(t:clients()) do
        c.screen = s --Move all clients
        c:tags({t})
    end

    if old_screen then
        -- Update all indexes
        for i,t2 in ipairs(old_screen.tags) do
            tag.setproperty(t2, "index", i)
        end

        -- Restore the old screen history if the tag was selected
        if sel then
            tag.history.restore(old_screen, 1)
        end
    end
end

--- Set a tag's screen
-- @deprecated awful.tag.setscreen
-- @see screen
-- @tparam screen s Screen
-- @tparam tag t The tag object
function tag.setscreen(s, t)
    -- For API consistency, the arguments have been swapped for Awesome 3.6
    -- this method is already deprecated, so be silent and swap the args
    if type(t) == "number" then
        s, t = t, s
    end

    gdebug.deprecate("Use t.screen = s instead of awful.tag.setscreen(t, s)", {deprecated_in=4})

    tag.object.set_screen(t, s)
end

--- Get a tag's screen
-- @deprecated awful.tag.getscreen
-- @see screen
-- @tparam[opt=awful.screen.focused().selected_taga] tag|nil t Tag object
-- @treturn screen The tag screen.
function tag.getscreen(t)
    gdebug.deprecate("Use t.screen instead of awful.tag.getscreen(t)", {deprecated_in=4})

    -- A new getter is not required

    t = t or ascreen.focused().selected_tag
    local prop = tag.getproperty(t, "screen")
    return prop and prop.index
end

--- Return a table with all visible tags
-- @deprecated awful.tag.selectedlist
-- @tparam screen s Screen.
-- @treturn table A table with all selected tags.
-- @see screen.selected_tags
function tag.selectedlist(s)
    gdebug.deprecate("Use s.selected_tags instead of awful.tag.selectedlist", {deprecated_in=4})

    s = get_screen(s or ascreen.focused())

    return s.selected_tags
end

--- Return only the first visible tag.
-- @deprecated awful.tag.selected
-- @tparam screen s Screen.
-- @see screen.selected_tag
function tag.selected(s)
    gdebug.deprecate("Use s.selected_tag instead of awful.tag.selected", {deprecated_in=4})

    s = get_screen(s or ascreen.focused())

    return s.selected_tag
end

--- The default master width factor
--
-- @beautiful beautiful.master_width_factor
-- @tparam[opt=0.5] number master_width_factor
-- @see master_width_factor
-- @see gap

--- The tag master width factor.
--
-- The master width factor is one of the 5 main properties used to configure
-- the `layout`. Each layout interpret (or ignore) this property differently.
--
-- See the layout suit documentation for information about how the master width
-- factor is used.
--
-- 
--
--<object class=&#34img-object&#34 data=&#34../images/AUTOGEN_screen_mwfact.svg&#34 alt=&#34Usage example&#34 type=&#34image/svg+xml&#34></object>
--
--
-- When multiple columns are used, the master width remains the same, but
-- the other columns split the remaining space among them:
--
-- 
--
--<object class=&#34img-object&#34 data=&#34../images/AUTOGEN_screen_mwfact2.svg&#34 alt=&#34Usage example&#34 type=&#34image/svg+xml&#34></object>
--
--
-- @property master_width_factor
-- @tparam[opt=beautiful.master_width_factor] number master_width_factor
-- @rangestart 0.0
-- @rangestop 1.0
-- @emits property::mwfact When the value changes (deprecated).
-- @emits property::master_width_factor When the value changes.
-- @see master_count
-- @see column_count
-- @see master_fill_policy
-- @see gap
-- @see awful.tag.incmwfact

function tag.object.set_master_width_factor(t, mwfact)
    if mwfact >= 0 and mwfact <= 1 then
        tag.setproperty(t, "mwfact", mwfact)
        tag.setproperty(t, "master_width_factor", mwfact)
    end
end

function tag.object.get_master_width_factor(t)
    return tag.getproperty(t, "master_width_factor")
        or beautiful.master_width_factor
        or defaults.master_width_factor
end

--- Set master width factor.
-- @deprecated awful.tag.setmwfact
-- @see master_fill_policy
-- @see master_width_factor
-- @tparam number mwfact Master width factor.
-- @tparam[opt=awful.screen.focused().selected_tag] tag t The tag to modify.
function tag.setmwfact(mwfact, t)
    gdebug.deprecate("Use t.master_width_factor = mwfact instead of awful.tag.setmwfact", {deprecated_in=4})

    tag.object.set_master_width_factor(t or ascreen.focused().selected_tag, mwfact)
end

--- Increase master width factor.
-- @staticfct awful.tag.incmwfact
-- @see master_width_factor
-- @tparam number add Value to add to master width factor.
-- @tparam[opt=awful.screen.focused().selected_tag] tag t The tag to modify.
-- @noreturn
function tag.incmwfact(add, t)
    t = t or t or ascreen.focused().selected_tag
    tag.object.set_master_width_factor(t, tag.object.get_master_width_factor(t) + add)
end

--- Get master width factor.
-- @deprecated awful.tag.getmwfact
-- @see master_width_factor
-- @see master_fill_policy
-- @tparam[opt] tag|nil t The tag.
function tag.getmwfact(t)
    gdebug.deprecate("Use t.master_width_factor instead of awful.tag.getmwfact", {deprecated_in=4})

    return tag.object.get_master_width_factor(t or ascreen.focused().selected_tag)
end

--- An ordered list of layouts.
-- `awful.tag.layout` Is usually defined in `rc.lua`. It store the list of
-- layouts used when selecting the previous and next layouts. This is the
-- default:
--
--     -- Table of layouts to cover with awful.layout.inc, order matters.
--     awful.layout.layouts = {
--         awful.layout.suit.floating,
--         awful.layout.suit.tile,
--         awful.layout.suit.tile.left,
--         awful.layout.suit.tile.bottom,
--         awful.layout.suit.tile.top,
--         awful.layout.suit.fair,
--         awful.layout.suit.fair.horizontal,
--         awful.layout.suit.spiral,
--         awful.layout.suit.spiral.dwindle,
--         awful.layout.suit.max,
--         awful.layout.suit.max.fullscreen,
--         awful.layout.suit.magnifier,
--         awful.layout.suit.corner.nw,
--         -- awful.layout.suit.corner.ne,
--         -- awful.layout.suit.corner.sw,
--         -- awful.layout.suit.corner.se,
--     }
--
-- @tfield table awful.tag.layouts
-- @tparam[opt={}] table awful.tag.layouts
-- @see request::layouts
-- @see awful.layout.append_default_layouts
-- @see awful.layout.append_default_layout
-- @see awful.layout.remove_default_layout

--- The tag client layout.
--
-- This property holds the layout. A layout can be either stateless or stateful.
-- Stateless layouts are used by default by Awesome. They tile clients without
-- any other overhead. They take an ordered list of clients and place them on
-- the screen. Stateful layouts create an object instance for each tags and
-- can store variables and metadata. Because of this, they are able to change
-- over time and be serialized (saved).
--
-- Both types of layouts have valid usage scenarios.
--
-- **Stateless layouts:**
--
-- These layouts are stored in `awful.layout.suit`. They expose a table with 2
-- fields:
--
-- * **name** (*string*): The layout name. This should be unique.
-- * **arrange** (*function*): The function called when the clients need to be
--     placed. The only parameter is a table or arguments returned by
--     `awful.layout.parameters`
--
-- The parameter table contains:
--
-- <table class='widget_list' border=1>
--  <tr style='font-weight: bold;'>
--   <th align='center'>Parameter </th>
--   <th align='center'>Type</th>
--   <th align='center'>Description</th>
--  </tr>
--  <tr><td>`workarea`</td><td> table </td><td>
--   A table with `x`,`y`, `width` and `height` keys.<br/>
--   All clients must be placed within this area.
--  </td></tr>
--  <tr><td align='center'>`geometry`</td><td> table </td><td>A table with the screen geometry.</td></tr>
--  <tr><td align='center'>`clients`</td><td> table </td><td>A list of the clients to place.</td></tr>
--  <tr><td align='center'>`screen`</td><td> screen </td><td>The screen.</td></tr>
--  <tr><td align='center'>`padding`</td><td> table </td><td>
--   A table with `left`, `right`, `top` and `bottom` keys.
--  </td></tr>
--  <tr>
--   <td align='center'>`useless_gap`</td><td> integer </td>
--   <td>The space that will be removed from the clients.</td>
--  </tr>
--  <tr><td align='center'>`geometries`</td><td> table </td><td>
--   Empty. Place the client as key and preferred geometry<br/>
--   as value. Do not call `:geometry()` directly.
--  </td></tr>
-- </table>
--
-- **Stateful layouts:**
--
-- The stateful layouts API is the same as stateless, but they are a function
-- returining a layout instead of a layout itself. They also should have an
-- `is_dynamic = true` property. If they don't, `awful.tag` will create a new
-- instance every time the layout is set. If they do, the instance will be
-- cached and re-used.
--
--
-- The client organized by the layout will fill the screen `tiling_area`
-- section:
--
-- 
--
--<object class=&#34img-object&#34 data=&#34../images/AUTOGEN_screen_taglayout.svg&#34 alt=&#34Usage example&#34 type=&#34image/svg+xml&#34></object>
--
--
-- @property layout
-- @tparam layout|function layout A layout table or a constructor function
-- @propertydefault The first non-nil value of either `self.layouts[1]` or
-- `awful.layout.layouts[1]` or `awful.layout.suit.floating`.
-- @functionparam table params A table containing the state of the layout (see the table above).
-- @functionnoreturn
-- @propemits false false
-- @see awful.tag.layouts
-- @see awful.layout.parameters

--- The (proposed) list of available layouts for this tag.
--
-- This property allows to define a subset (or superset) of layouts available
-- in the "rotation table". In the default configuration file, `Mod4+Space`
-- and `Mod4+Shift+Space` are used to switch between tags. The
-- `awful.widget.layoutlist` also uses this as its default layout filter.
--
-- By default, it will be the same as `awful.layout.layouts` unless there the
-- a layout not present is used. If that's the case they will be added at the
-- front of the list.
--
-- @property layouts
-- @tparam[opt=nil] table|nil layouts
-- @propertytype nil Use the current value of `awful.layout.layouts`.
-- @request tag layouts awful granted When the `layouts` property is first called
--  and there is no layouts, then that signal is called.
-- @see awful.layout.layouts
-- @see screen.workarea
-- @see screen.padding
-- @see layout

function tag.object.set_layout(t, layout)

    local template = nil

    -- Check if the signature match a stateful layout
    if type(layout) == "function" or (
        type(layout) == "table"
        and getmetatable(layout)
        and getmetatable(layout).__call
    ) then
        if not t.dynamic_layout_cache then
            t.dynamic_layout_cache = {}
        end

        local instance = t.dynamic_layout_cache[layout] or layout(t)

        -- Always make sure the layout is notified it is enabled
        if tag.getproperty(t, "screen").selected_tag == t and instance.wake_up then
            instance:wake_up()
        end

        -- Avoid creating the same layout twice, use layout:reset() to reset
        if instance.is_dynamic then
            t.dynamic_layout_cache[layout] = instance
        end

        template = layout
        layout = instance
    end

    tag.setproperty(t, "layout", layout)

    update_layouts(t, template or layout, layout)

    return layout
end

function tag.object.get_layouts(self)
    local override = tag.getproperty(self, "_layouts")

    if override then
        return override
    end

    -- Required to get the default/fallback list of layouts
    alayout = alayout or require("awful.layout")

    local cls = custom_layouts(self)

    -- Request some layouts. Maybe a new module was added?
    if #cls == 0 and not tag.getproperty(self, "_layouts_requested") then
        tag.setproperty(self, "_layouts_requested", true)
        local old_count = #cls
        self:emit_signal("request::layouts", "awful", {})

        -- When request::layouts is used, assume it takes precedence over
        -- the fallback.
        if #cls > old_count then
            tag.setproperty(self, "_layouts", gtable.clone(cls, false))
            return tag.getproperty(self, "_layouts")
        end

        return tag.object.get_layouts(self)
    end

    -- Without the clone, the custom_layouts would grow
    return #cls > 0 and gtable.merge(gtable.clone(cls, false), alayout.layouts) or
        alayout.layouts
end

function tag.object.set_layouts(self, layouts)
    tag.setproperty(self, "_custom_layouts", {})
    tag.setproperty(self, "_layouts", gtable.clone(layouts, false))

    local cur = tag.getproperty(self, "layout")
    update_layouts(self, cur, cur)

    self:emit_signal("property::layouts")
end

function tag.object.append_layout(self, layout)
    -- If the layouts are manually modified, don't request more.
    tag.setproperty(self, "_layouts_requested", true)

    local cls = tag.getproperty(self, "_layouts")

    if not cls then
        cls = custom_layouts(self)
    end

    table.insert(cls, layout)
    self:emit_signal("property::layouts")
end

function tag.object.append_layouts(self, layouts)
    -- If the layouts are manually modified, don't request more.
    tag.setproperty(self, "_layouts_requested", true)

    local cls = tag.getproperty(self, "_layouts")

    if not cls then
        cls = custom_layouts(self)
    end

    for _, l in ipairs(layouts) do
        table.insert(cls, l)
    end
    self:emit_signal("property::layouts")
end

function tag.object.remove_layout(self, layout)
    local cls = tag.getproperty(self, "_layouts")

    if not cls then
        cls = custom_layouts(self)
    end

    local pos = {}
    for k, l in ipairs(cls) do
        if l == layout then
            table.insert(pos, k)
        end
    end

    if #pos > 0 then
        for i=#pos, 1, -1 do
            table.remove(cls, i)
        end
        self:emit_signal("property::layouts")
    end

    return #pos > 0
end

function tag.object.get_layout(t)
    local l = tag.getproperty(t, "layout")
    if l then return l end

    local layouts = tag.getproperty(t, "_layouts")

    return layouts and layouts[1]
        or require("awful.layout.suit.floating")
end

--- Set layout.
-- @deprecated awful.tag.setlayout
-- @see layout
-- @param layout A layout table or a constructor function
-- @tparam tag t The tag to modify
-- @return The layout
function tag.setlayout(layout, t)
    gdebug.deprecate("Use t.layout = layout instead of awful.tag.setlayout", {deprecated_in=4})

    return tag.object.set_layout(t, layout)
end

--- Define if the tag must be deleted when the last client is untagged.
--
-- This is useful to create "throw-away" tags for operation like 50/50
-- (Windows "Aero Snap) side-by-side views. This keybinding code for this is:
--
--    local function aero_tag()
--        local c = client.focus
--
--        if not c then return end
--
--        local c2 = awful.client.focus.history.list[2]
--
--        if (not c2) or c2 == c then return end
--
--        local t = awful.tag.add("Aero", {
--            screen              = c.screen,
--            volatile            = true,
--            layout              = awful.layout.suit.tile,
--            master_width_factor = 0.5
--        })
--
--        t:clients({c, c2})
--
--        t:view_only()
--    end
--
-- 
--
--<object class=&#34img-object&#34 data=&#34../images/AUTOGEN_sequences_tag_volatile.svg&#34 alt=&#34Usage example&#34 type=&#34image/svg+xml&#34></object>
--
-- 
--     -- Create a non-volatile and a volatile tag.
--     awful.tag.add(&#34Non-Volatile&#34, {
--         screen   = screen[1],
--         layout   = awful.layout.suit.corner.nw,
--         volatile = false,
--     })
--  
--     awful.tag.add(&#34Volatile&#34, {
--         screen   = screen[1],
--         layout   = awful.layout.suit.corner.nw,
--         volatile = true,
--     })
--  
--     -- Add some clients.
--     for _, t in ipairs(screen[1].tags) do
--         for _ = 1, 5 do
--             awful.spawn(&#34xterm&#34, {tag = t})
--         end
--     end
--  
--     -- Kill all clients.
--     while #client.get() ~= 0 do
--         client.get()[1]:kill()
--     end
--
-- As you can see, the "Volatile" tag has been automatically discarded while
-- the "Non-volatile" tag is still there (but with zero clients).
--
-- @property volatile
-- @tparam[opt=false] boolean volatile
-- @propemits false false
-- @see delete

-- Volatile accessors are implicit

--- Set if the tag must be deleted when the last client is untagged
-- @deprecated awful.tag.setvolatile
-- @see volatile
-- @tparam boolean volatile If the tag must be deleted when the last client is untagged
-- @tparam[opt=awful.screen.focused().selected_tag] tag t The tag to modify.
function tag.setvolatile(volatile, t)
    gdebug.deprecate("Use t.volatile = volatile instead of awful.tag.setvolatile", {deprecated_in=4})

    tag.setproperty(t, "volatile", volatile)
end

--- Get if the tag must be deleted when the last client closes
-- @deprecated awful.tag.getvolatile
-- @see volatile
-- @tparam[opt=opt=awful.screen.focused().selected_tag] tag t The tag to modify.
-- @treturn boolean If the tag will be deleted when the last client is untagged
function tag.getvolatile(t)
    gdebug.deprecate("Use t.volatile instead of awful.tag.getvolatile", {deprecated_in=4})

    return tag.getproperty(t, "volatile") or false
end

--- The default gap.
--
-- @beautiful beautiful.useless_gap
-- @tparam[opt=0] number useless_gap
-- @see gap
-- @see gap_single_client

--- The gap (spacing, also called `useless_gap`) between clients.
--
-- This property allows to waste space on the screen in the name of style,
-- unicorns and readability.
--
-- In this example, the value of `gap` is set to 20:
--
-- 
--
--<object class=&#34img-object&#34 data=&#34../images/AUTOGEN_screen_gaps.svg&#34 alt=&#34Usage example&#34 type=&#34image/svg+xml&#34></object>
--
--
-- Compared to setting to the (very high) value of 50:
--
-- 
--
--<object class=&#34img-object&#34 data=&#34../images/AUTOGEN_screen_gaps2.svg&#34 alt=&#34Usage example&#34 type=&#34image/svg+xml&#34></object>
--
--
-- @property gap
-- @tparam[opt=beautiful.useless_gap] integer gap The value has to be greater than zero.
-- @propertyunit pixel
-- @negativeallowed false
-- @emits property::useless_gap When the gap changes.
-- @see gap_single_client
-- @see awful.tag.incgap

function tag.object.set_gap(t, useless_gap)
    if useless_gap >= 0 then
        tag.setproperty(t, "useless_gap", useless_gap)
    end
end

function tag.object.get_gap(t)
    return tag.getproperty(t, "useless_gap")
        or beautiful.useless_gap
        or defaults.gap
end

--- Set the spacing between clients
-- @deprecated awful.tag.setgap
-- @see gap
-- @tparam number|nil useless_gap The spacing between clients
-- @tparam[opt=awful.screen.focused().selected_tag] tag t The tag to modify.
function tag.setgap(useless_gap, t)
    gdebug.deprecate("Use t.gap = useless_gap instead of awful.tag.setgap", {deprecated_in=4})

    tag.object.set_gap(t or ascreen.focused().selected_tag, useless_gap)
end

--- Increase the spacing between clients
-- @staticfct awful.tag.incgap
-- @tparam number add Value to add to the spacing between clients
-- @tparam[opt=awful.screen.focused().selected_tag] tag t The tag to modify.
-- @noreturn
-- @see gap
-- @see beautiful.useless_gap
function tag.incgap(add, t)
    t = t or t or ascreen.focused().selected_tag
    tag.object.set_gap(t, tag.object.get_gap(t) + add)
end

--- Enable gaps for a single client.
--
-- @beautiful beautiful.gap_single_client
-- @tparam[opt=true] boolean gap_single_client
-- @see gap
-- @see gap_single_client

--- Enable gaps for a single client.
--
-- If the gaps are used purely for readability when multiple
-- clients are tiled, then it may make sense to disable it
-- when there is only a single client (to recover that space).
-- In that case, set `gap_single_client` to `false`.
--
-- Default (with a 20px gap):
--
-- 
--
--<object class=&#34img-object&#34 data=&#34../images/AUTOGEN_screen_gap_single_client_true.svg&#34 alt=&#34Usage example&#34 type=&#34image/svg+xml&#34></object>
--
--
-- when set to false:
--
-- 
--
--<object class=&#34img-object&#34 data=&#34../images/AUTOGEN_screen_gap_single_client_false.svg&#34 alt=&#34Usage example&#34 type=&#34image/svg+xml&#34></object>
--
--
-- @property gap_single_client
-- @tparam[opt=beautiful.gap_single_client] boolean gap_single_client Enable gaps for a single client
-- @propemits false false
-- @see awful.tag.incgap

function tag.object.set_gap_single_client(t, gap_single_client)
    tag.setproperty(t, "gap_single_client", gap_single_client == true)
end

function tag.object.get_gap_single_client(t)
    local val = tag.getproperty(t, "gap_single_client")
    if val ~= nil then
        return val
    end
    val = beautiful.gap_single_client
    if val ~= nil then
        return val
    end
    return defaults.gap_single_client
end

--- Get the spacing between clients.
-- @deprecated awful.tag.getgap
-- @see gap
-- @tparam[opt=tag.selected()] tag t The tag.
-- @tparam[opt] int numclients Number of (tiled) clients.  Passing this will
--   return 0 for a single client.  You can override this function to change
--   this behavior.
function tag.getgap(t, numclients)
    gdebug.deprecate("Use t.gap instead of awful.tag.getgap", {deprecated_in=4})

    if numclients == 1 then
        return 0
    end

    return tag.object.get_gap(t or ascreen.focused().selected_tag)
end

--- The default fill policy.
--
-- ** Possible values**:
--
-- * *expand*: Take all the space
-- * *master_width_factor*: Only take the ratio defined by the
--   `master_width_factor`
--
-- @beautiful beautiful.master_fill_policy
-- @tparam[opt="expand"] string master_fill_policy
-- @see master_fill_policy

--- Set size fill policy for the master client(s).
--
-- Some multi-column layouts can be configured so that the space is
-- redistributed when there is not enough clients to fill all columns.
--
-- This is the default behavior of the `tile.left` layout (*expand*):
--
-- 
--
--<object class=&#34img-object&#34 data=&#34../images/AUTOGEN_screen_mfpol2.svg&#34 alt=&#34Usage example&#34 type=&#34image/svg+xml&#34></object>
--
--
-- This is what happends when set to `master_width_factor`:
--
-- 
--
--<object class=&#34img-object&#34 data=&#34../images/AUTOGEN_screen_mfpol.svg&#34 alt=&#34Usage example&#34 type=&#34image/svg+xml&#34></object>
--
--
-- The remaining space that would have been used for the second column is
-- redistributed on both side.
--
-- @property master_fill_policy
-- @tparam[opt=beautiful.master_fill_policy] string master_fill_policy
-- @propertyvalue "expand" Take all the space
-- @propertyvalue "master_width_factor" Only take the ratio defined by the
--   `master_width_factor`
-- @propemits false false
-- @see awful.tag.togglemfpol

function tag.object.get_master_fill_policy(t)
    return tag.getproperty(t, "master_fill_policy")
        or beautiful.master_fill_policy
        or defaults.master_fill_policy
end

--- Set size fill policy for the master client(s)
-- @deprecated awful.tag.setmfpol
-- @see master_fill_policy
-- @tparam string policy Can be set to
-- "expand" (fill all the available workarea) or
-- `master_width_factor` (fill only an area inside the master width factor)
-- @tparam[opt=tag.selected()] tag t The tag to modify
-- @noreturn
function tag.setmfpol(policy, t)
    gdebug.deprecate("Use t.master_fill_policy = policy instead of awful.tag.setmfpol", {deprecated_in=4})

    t = t or ascreen.focused().selected_tag
    tag.setproperty(t, "master_fill_policy", policy)
end

--- Toggle size fill policy for the master client(s)
-- between "expand" and `master_width_factor`.
-- @staticfct awful.tag.togglemfpol
-- @noreturn
-- @see master_fill_policy
-- @tparam[opt=awful.screen.focused().selected_tag] tag t The tag to modify.
function tag.togglemfpol(t)
    t = t or ascreen.focused().selected_tag

    if tag.getmfpol(t) == "expand" then
        tag.setproperty(t, "master_fill_policy", "master_width_factor")
    else
        tag.setproperty(t, "master_fill_policy", "expand")
    end
end

--- Get size fill policy for the master client(s)
-- @deprecated awful.tag.getmfpol
-- @see master_fill_policy
-- @tparam[opt=tag.selected()] tag t The tag
-- @treturn string Possible values are
-- "expand" (fill all the available workarea, default one) or
-- "master_width_factor" (fill only an area inside the master width factor)
function tag.getmfpol(t)
    gdebug.deprecate("Use t.master_fill_policy instead of awful.tag.getmfpol", {deprecated_in=4})

    t = t or ascreen.focused().selected_tag
    return tag.getproperty(t, "master_fill_policy")
        or beautiful.master_fill_policy
        or defaults.master_fill_policy
end

--- The default number of master windows.
--
-- @beautiful beautiful.master_count
-- @tparam[opt=1] integer master_count
-- @see master_count

--- Set the number of master windows.
--
-- 
--
--<object class=&#34img-object&#34 data=&#34../images/AUTOGEN_sequences_tag_master_count.svg&#34 alt=&#34Usage example&#34 type=&#34image/svg+xml&#34></object>
--
-- 
--     -- Create a tag with master count of 1 and tag with count of 2
--     awful.tag.add(&#34Master 1&#34, {
--         screen   = screen[1],
--         layout   = awful.layout.suit.tile,
--         master_count = 1,
--     })
--  
--     awful.tag.add(&#34Master 2&#34, {
--         screen   = screen[1],
--         layout   = awful.layout.suit.tile,
--         master_count = 2,
--     })
--  
--     -- Add some clients.
--     for _, t in ipairs(screen[1].tags) do
--         for _ = 1, 5 do
--             awful.spawn(&#34xterm&#34, {tag = t})
--         end
--     end
--
-- @property master_count
-- @tparam[opt=beautiful.master_count] integer master_count Only positive values are accepted
-- @rangestart 1
-- @emits property::nmaster Deprecated.
-- @emits property::master_count When the value changes.
-- @see awful.tag.incnmaster

function tag.object.set_master_count(t, nmaster)
    if nmaster >= 0 then
        tag.setproperty(t, "nmaster", nmaster)
        tag.setproperty(t, "master_count", nmaster)
    end
end

function tag.object.get_master_count(t)
    return tag.getproperty(t, "master_count")
        or beautiful.master_count
        or defaults.master_count
end

--- The number of master clients.
-- @deprecated awful.tag.setnmaster
-- @see master_count
-- @tparam number nmaster The number of master windows.
-- @tparam[opt] tag t The tag.
function tag.setnmaster(nmaster, t)
    gdebug.deprecate("Use t.master_count = nmaster instead of awful.tag.setnmaster", {deprecated_in=4})

    tag.object.set_master_count(t or ascreen.focused().selected_tag, nmaster)
end

--- Get the number of master windows.
-- @deprecated awful.tag.getnmaster
-- @see master_count
-- @tparam[opt] tag t The tag.
function tag.getnmaster(t)
    gdebug.deprecate("Use t.master_count instead of awful.tag.setnmaster", {deprecated_in=4})

    t = t or ascreen.focused().selected_tag
    return tag.getproperty(t, "master_count") or 1
end

--- Increase the number of master windows.
-- @staticfct awful.tag.incnmaster
-- @see master_count
-- @tparam number add Value to add to number of master windows.
-- @tparam[opt=awful.screen.focused().selected_tag] tag t The tag to modify.
-- @tparam[opt=false] boolean sensible Limit nmaster based on the number of
--   visible tiled windows?
-- @noreturn
function tag.incnmaster(add, t, sensible)
    t = t or ascreen.focused().selected_tag

    if sensible then
        local screen = get_screen(tag.getproperty(t, "screen"))
        local ntiled = #screen.tiled_clients

        local nmaster = tag.object.get_master_count(t)
        if nmaster > ntiled then
            nmaster = ntiled
        end

        local newnmaster = nmaster + add
        if newnmaster > ntiled then
            newnmaster = ntiled
        end
        tag.object.set_master_count(t, newnmaster)
    else
        tag.object.set_master_count(t, tag.object.get_master_count(t) + add)
    end
end

--- Set the tag icon.
--
-- 
--
--<object class=&#34img-object&#34 data=&#34../images/AUTOGEN_wibox_awidget_taglist_icon.svg&#34 alt=&#34Usage example&#34 type=&#34image/svg+xml&#34></object>
--
-- 
--     awful.tag.add(&#34one&#34, {})
--  
--     awful.tag.add(&#34two&#34, {
--         icon = beautiful.awesome_icon
--     })
--  
--     awful.tag.add(&#34three&#34, {})
--  
--
-- @property icon
-- @tparam[opt=nil] image|nil icon
-- @propemits false false
-- @see awful.widget.taglist
-- @see gears.surface

-- accessors are implicit.

--- Set the tag icon
-- @deprecated awful.tag.seticon
-- @tparam gears.surface|string icon The icon to set, either path or image object
-- @tparam tag tag The tag
-- @see icon
function tag.seticon(icon, _tag)
    gdebug.deprecate("Use t.icon = icon instead of awful.tag.seticon", {deprecated_in=4})

    _tag = _tag or ascreen.focused().selected_tag
    tag.setproperty(_tag, "icon", icon)
end

--- Get the tag icon
-- @deprecated awful.tag.geticon
-- @see icon
-- @tparam tag tag The tag
function tag.geticon(_tag)
    gdebug.deprecate("Use t.icon instead of awful.tag.geticon", {deprecated_in=4})

    _tag = _tag or ascreen.focused().selected_tag
    return tag.getproperty(_tag, "icon")
end

--- The default number of columns.
--
-- @beautiful beautiful.column_count
-- @tparam[opt=1] integer column_count
-- @see column_count

--- Set the number of columns.
--
-- 
--
--<object class=&#34img-object&#34 data=&#34../images/AUTOGEN_sequences_tag_column_count.svg&#34 alt=&#34Usage example&#34 type=&#34image/svg+xml&#34></object>
--
-- 
--     -- Create a tag with column count of 1 and tag with count of 2
--     awful.tag.add(&#341 column&#34, {
--         screen   = screen[1],
--         layout   = awful.layout.suit.tile,
--         column_count = 1,
--     })
--  
--     awful.tag.add(&#342 columns&#34, {
--         screen   = screen[1],
--         layout   = awful.layout.suit.tile,
--         column_count = 2,
--     })
--  
--     awful.tag.add(&#343 columns&#34, {
--         screen   = screen[1],
--         layout   = awful.layout.suit.tile,
--         column_count = 3,
--     })
--  
--     -- Add some clients.
--     for _, t in ipairs(screen[1].tags) do
--         for _ = 1, 6 do
--             awful.spawn(&#34xterm&#34, {tag = t})
--         end
--     end
--
-- @property column_count
-- @tparam[opt=beautiful.column_count or 1] integer column_count Has to be greater than 1
-- @rangestart 1
-- @emits property::ncol Deprecated.
-- @emits property::column_count When the value changes.
-- @see awful.tag.incncol

function tag.object.set_column_count(t, ncol)
    if ncol >= 1 then
        tag.setproperty(t, "ncol", ncol)
        tag.setproperty(t, "column_count", ncol)
    end
end

function tag.object.get_column_count(t)
    return tag.getproperty(t, "column_count")
        or beautiful.column_count
        or defaults.column_count
end

--- Set number of column windows.
-- @deprecated awful.tag.setncol
-- @see column_count
-- @tparam integer ncol The number of column.
-- @tparam[opt=awful.screen.focused().selected_tag] tag t The tag to modify.
function tag.setncol(ncol, t)
    gdebug.deprecate("Use t.column_count = new_index instead of awful.tag.setncol", {deprecated_in=4})

    t = t or ascreen.focused().selected_tag
    if ncol >= 1 then
        tag.setproperty(t, "ncol", ncol)
        tag.setproperty(t, "column_count", ncol)
    end
end

--- Get number of column windows.
-- @deprecated awful.tag.getncol
-- @see column_count
-- @tparam[opt] tag t The tag.
function tag.getncol(t)
    gdebug.deprecate("Use t.column_count instead of awful.tag.getncol", {deprecated_in=4})

    t = t or ascreen.focused().selected_tag
    return tag.getproperty(t, "column_count") or 1
end

--- Increase number of column windows.
-- @staticfct awful.tag.incncol
-- @tparam number add Value to add to number of column windows.
-- @tparam[opt=awful.screen.focused().selected_tag] tag t The tag to modify.
-- @tparam[opt=false] boolean sensible Limit column_count based on the number
--   of visible tiled windows?
-- @noreturn
function tag.incncol(add, t, sensible)
    t = t or ascreen.focused().selected_tag

    if sensible then
        local screen = get_screen(tag.getproperty(t, "screen"))
        local ntiled = #screen.tiled_clients
        local nmaster = tag.object.get_master_count(t)
        local nsecondary = ntiled - nmaster

        local ncol = tag.object.get_column_count(t)
        if ncol > nsecondary then
            ncol = nsecondary
        end

        local newncol = ncol + add
        if newncol > nsecondary then
            newncol = nsecondary
        end

        tag.object.set_column_count(t, newncol)
    else
        tag.object.set_column_count(t, tag.object.get_column_count(t) + add)
    end
end

--- View no tag.
--
-- 
--
--<object class=&#34img-object&#34 data=&#34../images/AUTOGEN_sequences_tag_viewnone.svg&#34 alt=&#34Usage example&#34 type=&#34image/svg+xml&#34></object>
--
-- 
--     -- Calling awful.tag.new
--     awful.tag({ &#34one&#34, &#34two&#34, &#34three&#34, &#34four&#34 }, screen[1])
--      
--     -- Manually select some tags (tag 1 was auto selected).
--     screen[1].tags[3].selected = true
--     screen[1].tags[4].selected = true
--  
--     -- Deselect all tags.
--     awful.tag.viewnone()
--
-- @staticfct awful.tag.viewnone
-- @tparam[opt] int|screen screen The screen.
-- @noreturn
function tag.viewnone(screen)
    screen = screen or ascreen.focused()
    local tags = screen.tags
    for _, t in pairs(tags) do
        t.selected = false
    end
end

--- Select a tag relative to the currently selected one.
--
-- Note that this doesn't work well with multiple selection.
--
-- 
--
--<object class=&#34img-object&#34 data=&#34../images/AUTOGEN_sequences_tag_viewidx.svg&#34 alt=&#34Usage example&#34 type=&#34image/svg+xml&#34></object>
--
-- 
--     -- Calling awful.tag.new
--     awful.tag({ &#34one&#34, &#34two&#34, &#34three&#34, &#34four&#34 }, screen[1])
--      
--     screen[1].tags[2]:view_only()
--  
--     -- Select the tag relative to idx 2.
--     awful.tag.viewidx(2)
--  
--     -- Select the tag relative to idx -2.
--     awful.tag.viewidx(-2)
--
-- This is equivalent to `screen.tags[i]:view_only()`
-- @staticfct awful.tag.viewidx
-- @see screen.tags
-- @tparam number i The **relative** index to see.
-- @tparam[opt] screen screen The screen.
-- @noreturn
-- @see awful.tag.viewnext
-- @see awful.tag.viewprev
function tag.viewidx(i, screen)
    screen = get_screen(screen or ascreen.focused())
    local tags = screen.tags
    local showntags = {}
    for _, t in ipairs(tags) do
        if not tag.getproperty(t, "hide") then
            table.insert(showntags, t)
        end
    end
    local sel = screen.selected_tag
    tag.viewnone(screen)
    for k, t in ipairs(showntags) do
        if t == sel then
            showntags[gmath.cycle(#showntags, k + i)].selected = true
        end
    end
    screen:emit_signal("tag::history::update")
end

--- Get a tag's index in the gettags() table.
-- @deprecated awful.tag.getidx
-- @see index
-- @tparam tag query_tag The tag object to find. [selected()]
-- @treturn integer|nil The index of the tag, nil if the tag is not found.
function tag.getidx(query_tag)
    gdebug.deprecate("Use t.index instead of awful.tag.getidx", {deprecated_in=4})

    return tag.object.get_index(query_tag or ascreen.focused().selected_tag)
end


--- View next tag. This is the same as `tag.viewidx(1)`.
--
-- Note that this doesn't work well with multiple selection.
--
-- 
--
--<object class=&#34img-object&#34 data=&#34../images/AUTOGEN_sequences_tag_viewnext.svg&#34 alt=&#34Usage example&#34 type=&#34image/svg+xml&#34></object>
--
-- 
--     -- Calling awful.tag.new
--     awful.tag({ &#34one&#34, &#34two&#34, &#34three&#34, &#34four&#34 }, screen[1])
--      
--     screen[1].tags[3]:view_only()
--  
--     -- Select the next tag.
--     awful.tag.viewnext()
--  
--     -- Select the next tag (again).
--     awful.tag.viewnext()
--
-- @staticfct awful.tag.viewnext
-- @tparam screen screen The screen.
-- @noreturn
-- @see awful.tag.viewidx
-- @see awful.tag.viewprev
function tag.viewnext(screen)
    tag.viewidx(1, screen)
end

--- View previous tag. This is the same a `tag.viewidx(-1)`.
--
-- Note that this doesn't work well with multiple selection.
--
-- 
--
--<object class=&#34img-object&#34 data=&#34../images/AUTOGEN_sequences_tag_viewprev.svg&#34 alt=&#34Usage example&#34 type=&#34image/svg+xml&#34></object>
--
-- 
--     -- Calling awful.tag.new
--     awful.tag({ &#34one&#34, &#34two&#34, &#34three&#34, &#34four&#34 }, screen[1])
--      
--     screen[1].tags[2]:view_only()
--  
--     -- Select the previous tag.
--     awful.tag.viewprev()
--  
--     -- Select the previous tag (again).
--     awful.tag.viewprev()
--
-- @staticfct awful.tag.viewprev
-- @tparam screen screen The screen.
-- @noreturn
-- @see awful.tag.viewidx
-- @see awful.tag.viewnext
function tag.viewprev(screen)
    tag.viewidx(-1, screen)
end

--- View only a tag.
--
-- 
--
--<object class=&#34img-object&#34 data=&#34../images/AUTOGEN_sequences_tag_view_only.svg&#34 alt=&#34Usage example&#34 type=&#34image/svg+xml&#34></object>
--
-- 
--     -- Calling awful.tag.new
--     awful.tag({ &#34one&#34, &#34two&#34, &#34three&#34, &#34four&#34 }, screen[1])
--      
--     -- Manually select some tags (tag 1 was auto selected).
--     screen[1].tags[3].selected = true
--     screen[1].tags[4].selected = true
--  
--     -- Call :view_only() on the second tag.
--     screen[1].tags[2]:view_only()
--
-- @method view_only
-- @noreturn
-- @see selected
function tag.object.view_only(self)
    local tags = self.screen.tags
    -- First, untag everyone except the viewed tag.
    for _, _tag in pairs(tags) do
        if _tag ~= self then
            _tag.selected = false
        end
    end
    -- Then, set this one to selected.
    -- We need to do that in 2 operations so we avoid flickering and several tag
    -- selected at the same time.
    self.selected = true
    capi.screen[self.screen]:emit_signal("tag::history::update")
end

--- View only a tag.
-- @deprecated awful.tag.viewonly
-- @noreturn
-- @see tag.view_only
-- @tparam tag t The tag object.
function tag.viewonly(t)
    gdebug.deprecate("Use t:view_only() instead of awful.tag.viewonly", {deprecated_in=4})

    tag.object.view_only(t)
end

--- View only a set of tags.
--
-- If `maximum` is set, there will be a limit on the number of new tag being
-- selected. The tags already selected do not count. To do nothing if one or
-- more of the tags are already selected, set `maximum` to zero.
--
-- @staticfct awful.tag.viewmore
-- @tparam table tags A table with tags to view only.
-- @tparam[opt] screen screen The screen of the tags.
-- @tparam[opt=#tags] number maximum The maximum number of tags to select.
-- @noreturn
function tag.viewmore(tags, screen, maximum)
    maximum = maximum or #tags
    local selected = 0
    screen = get_screen(screen or ascreen.focused())
    local screen_tags = screen.tags
    for _, _tag in ipairs(screen_tags) do
        if not gtable.hasitem(tags, _tag) then
            _tag.selected = false
        elseif _tag.selected then
            selected = selected + 1
        end
    end
    for _, _tag in ipairs(tags) do
        if selected == 0 and maximum == 0 then
            _tag.selected = true
            break
        end

        if selected >= maximum then break end

        if not _tag.selected then
            selected = selected + 1
            _tag.selected = true
        end
    end
    screen:emit_signal("tag::history::update")
end

--- Toggle selection of a tag
-- @staticfct awful.tag.viewtoggle
-- @tparam tag t Tag to be toggled
-- @noreturn
-- @see selected
function tag.viewtoggle(t)
    t.selected = not t.selected
    capi.screen[tag.getproperty(t, "screen")]:emit_signal("tag::history::update")
end

--- Get tag data table.
--
-- Do not use.
--
-- @deprecated awful.tag.getdata
-- @tparam tag t The tag.
-- @treturn table The data table.
function tag.getdata(t)
    return t._private.awful_tag_properties
end

--- Get a tag property.
--
-- Use `_tag.prop` directly.
--
-- @deprecated awful.tag.getproperty
-- @tparam tag t The tag.
-- @tparam string prop The property name.
-- @return The property.
function tag.getproperty(t, prop)
    if not t then return end -- FIXME: Turn this into an error?

    if t._private.awful_tag_properties then
       return t._private.awful_tag_properties[prop]
    end
end

--- Set a tag property.
-- This properties are internal to awful. Some are used to draw taglist, or to
-- handle layout, etc.
--
-- Use `t.prop = value`
--
-- @deprecated awful.tag.setproperty
-- @tparam tag t The tag.
-- @tparam string prop The property name.
-- @param value The value.
function tag.setproperty(t, prop, value)
    if not t._private.awful_tag_properties then
        t._private.awful_tag_properties = {}
    end

    if t._private.awful_tag_properties[prop] ~= value then
        t._private.awful_tag_properties[prop] = value
        t:emit_signal("property::" .. prop)
    end
end

--- Tag a client with the set of current tags.
-- @deprecated awful.tag.withcurrent
-- @tparam client c The client to tag.
-- @noreturn
function tag.withcurrent(c)
    gdebug.deprecate("Use c:to_selected_tags() instead of awful.tag.selectedlist", {deprecated_in=4})

    -- It can't use c:to_selected_tags() because awful.tag is loaded before
    -- awful.client

    local tags = {}
    for _, t in ipairs(c:tags()) do
        if get_screen(tag.getproperty(t, "screen")) == get_screen(c.screen) then
            table.insert(tags, t)
        end
    end
    if #tags == 0 then
        tags = c.screen.selected_tags
    end
    if #tags == 0 then
        tags = c.screen.tags
    end
    if #tags ~= 0 then
        c:tags(tags)
    end
end

local function attached_connect_signal_screen(screen, sig, func)
    screen = get_screen(screen)
    capi.tag.connect_signal(sig, function(t)
        if get_screen(tag.getproperty(t, "screen")) == screen then
            func(t)
        end
    end)
end

--- Add a signal to all attached tags and all tags that will be attached in the
-- future. When a tag is detached from the screen, its signal is removed.
--
-- @staticfct awful.tag.attached_connect_signal
-- @tparam screen|nil screen The screen concerned, or all if `nil`.
-- @tparam string signal The signal name.
-- @tparam function callback
-- @noreturn
function tag.attached_connect_signal(screen, ...)
    if screen then
        attached_connect_signal_screen(screen, ...)
    else
        capi.tag.connect_signal(...)
    end
end

-- Register standard signals.
capi.client.connect_signal("property::screen", function(c)
    -- First, the delayed timer is necessary to avoid a race condition with
    -- `ruled.client`. It is also messing up the tags before the user have a
    -- chance to set them manually.
    timer.delayed_call(function()
        if not c.valid then
            return
        end
        local tags, new_tags = c:tags(), {}

        for _, t in ipairs(tags) do
            if t.screen == c.screen then
                table.insert(new_tags, t)
            end
        end

        if #new_tags == 0 then
            --TODO v5: Add a context as first param
            c:emit_signal("request::tag", nil, {reason="screen"})
        elseif #new_tags < #tags then
            c:tags(new_tags)
        end
    end)
end)

-- Keep track of the number of urgent clients.
local function update_urgent(t, modif)
    local count = tag.getproperty(t, "urgent_count") or 0
    count = (count + modif) >= 0 and (count + modif) or 0
    tag.setproperty(t, "urgent"      , count > 0)
    tag.setproperty(t, "urgent_count", count    )
end

-- Update the urgent counter when a client is tagged.
local function client_tagged(c, t)
    if c.urgent then
        update_urgent(t, 1)
    end
end

-- Update the urgent counter when a client is untagged.
local function client_untagged(c, t)
    if c.urgent then
        update_urgent(t, -1)
    end

    if #t:clients() == 0 and tag.getproperty(t, "volatile") then
        tag.object.delete(t)
    end
end

-- Count the urgent clients.
local function urgent_callback(c)
    for _,t in ipairs(c:tags()) do
        update_urgent(t, c.urgent and 1 or -1)
    end
end

capi.client.connect_signal("property::urgent", urgent_callback)
capi.client.connect_signal("untagged", client_untagged)
capi.client.connect_signal("tagged", client_tagged)
capi.tag.connect_signal("request::select", tag.object.view_only)

--- Emitted when the number of urgent clients on this tag changes.
-- @signal property::urgent
-- @tparam boolean urgent `true` if there is at least one urgent client on the tag.
-- @see client.urgent

--- Emitted when the number of urgent clients on this tag changes.
-- @signal property::urgent_count
-- @tparam integer count The number of urgent clients on the tag.
-- @see client.urgent

--- Emitted when a screen is removed.
--
-- This can be used to salvage existing tags by moving them to a new
-- screen (or creating a virtual screen).
--
-- By default, there is no handler for this request and the tags will be deleted.
-- To prevent this, an handler for this request must simply set a new screen
-- for the tag.
--
-- @signal request::screen
-- @tparam string context Why it was called.

--- Emitted after `request::screen` if no new screen has been set.
-- The tag will be deleted, this is a last chance to move its clients
-- before they are sent to a fallback tag. Connect to `request::screen`
-- if you wish to salvage the tag.
-- @signal removal-pending

capi.screen.connect_signal("tag::history::update", tag.history.update)

-- Make sure the history is set early
timer.delayed_call(function()
    for s in capi.screen do
        s:emit_signal("tag::history::update")
    end
end)

capi.screen.connect_signal("removed", function(s)
    -- First give other code a chance to move the tag to another screen
    for _, t in pairs(s.tags) do
        t:emit_signal("request::screen", "removed")
    end
    -- Everything that's left: Tell everyone that these tags go away (other code
    -- could e.g. save clients)
    for _, t in pairs(s.tags) do
        t:emit_signal("removal-pending")
    end
    -- Give other code yet another change to save clients
    for _, c in pairs(capi.client.get(s)) do
        --TODO v5: Add a context as first param
        c:emit_signal("request::tag", nil, { reason = "screen-removed" })
    end
    -- Then force all clients left to go somewhere random
    local fallback = nil
    for other_screen in capi.screen do
        if #other_screen.tags > 0 then
            fallback = other_screen.tags[1]
            break
        end
    end
    for _, t in pairs(s.tags) do
        t:delete(fallback, true)
    end
    -- If any tag survived until now, forcefully get rid of it
    for _, t in pairs(s.tags) do
        t.activated = false

        if t._private.awful_tag_properties then
            t._private.awful_tag_properties.screen = nil
        end
    end
    data.history[s] = nil
end)

function tag.mt:__call(...)
    return tag.new(...)
end

-- Extend the luaobject
-- `awful.tag.setproperty` currently handle calling the setter method itself
-- while `awful.tag.getproperty`.
object.properties(capi.tag, {
    getter_class    = tag.object,
    setter_class    = tag.object,
    getter_fallback = tag.getproperty,
    setter_fallback = tag.setproperty,
})

--

return setmetatable(tag, tag.mt)

-- vim: filetype=lua:expandtab:shiftwidth=4:tabstop=8:softtabstop=4:textwidth=80
