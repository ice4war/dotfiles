---------------------------------------------------------------------------
-- An interactive mouse based slider widget.
--
--
--
--<object class=&#34img-object&#34 data=&#34../images/AUTOGEN_wibox_widget_defaults_slider.svg&#34 alt=&#34Usage example&#34 type=&#34image/svg+xml&#34></object>
--
-- @usage
-- local widget = wibox.widget {
--     bar_shape           = gears.shape.rounded_rect,
--     bar_height          = 3,
--     bar_color           = beautiful.border_color,
--     handle_color        = beautiful.bg_normal,
--     handle_shape        = gears.shape.circle,
--     handle_border_color = beautiful.border_color,
--     handle_border_width = 1,
--     value               = 25,
--     widget              = wibox.widget.slider,
-- }
--  
-- -- Connect to `property::value` to use the value on change
-- widget:connect_signal(&#34property::value&#34, function(_, new_value)
--     naughty.notify { title = &#34Slider changed&#34, message = tostring(new_value) }
-- end)
--
-- @author Grigory Mishchenko &lt;grishkokot@gmail.com&gt;
-- @author Emmanuel Lepage Vallee &lt;elv1313@gmail.com&gt;
-- @copyright 2015 Grigory Mishchenko, 2016 Emmanuel Lepage Vallee
-- @widgetmod wibox.widget.slider
-- @supermodule wibox.widget.base
---------------------------------------------------------------------------

local setmetatable = setmetatable
local type = type
local color = require("gears.color")
local gtable = require("gears.table")
local beautiful = require("beautiful")
local base = require("wibox.widget.base")
local shape = require("gears.shape")
local capi = {
    mouse        = mouse,
    mousegrabber = mousegrabber,
    root         = root,
}

local slider = {mt={}}

--- The slider handle shape.
--
--
--
--<object class=&#34img-object&#34 data=&#34../images/AUTOGEN_wibox_widget_slider_handle_shape.svg&#34 alt=&#34Usage example&#34 type=&#34image/svg+xml&#34></object>
--
--
-- @property handle_shape
-- @tparam shape|nil handle_shape
-- @propemits true false
-- @propbeautiful
-- @see gears.shape

--- The slider handle color.
--
--
--
--<object class=&#34img-object&#34 data=&#34../images/AUTOGEN_wibox_widget_slider_handle_color.svg&#34 alt=&#34Usage example&#34 type=&#34image/svg+xml&#34></object>
--
--
-- @property handle_color
-- @propbeautiful
-- @tparam color|nil handle_color
-- @propemits true false

--- The slider handle margins.
--
--
--
--<object class=&#34img-object&#34 data=&#34../images/AUTOGEN_wibox_widget_slider_handle_margins.svg&#34 alt=&#34Usage example&#34 type=&#34image/svg+xml&#34></object>
--
--
-- @property handle_margins
-- @tparam[opt={}] table|number|nil handle_margins
-- @tparam[opt=0] number handle_margins.left
-- @tparam[opt=0] number handle_margins.right
-- @tparam[opt=0] number handle_margins.top
-- @tparam[opt=0] number handle_margins.bottom
-- @propertyunit pixel
-- @propertytype number A single value used for all sides.
-- @propertytype table A different value for each side. The side names are:
-- @negativeallowed true
-- @propemits true false
-- @propbeautiful

--- The slider handle width.
--
--
--
--<object class=&#34img-object&#34 data=&#34../images/AUTOGEN_wibox_widget_slider_handle_width.svg&#34 alt=&#34Usage example&#34 type=&#34image/svg+xml&#34></object>
--
--
-- @property handle_width
-- @tparam number|nil handle_width
-- @negativeallowed false
-- @propertyunit pixel
-- @propemits true false
-- @propbeautiful

--- The handle border_color.
--
--
--
--<object class=&#34img-object&#34 data=&#34../images/AUTOGEN_wibox_widget_slider_handle_border.svg&#34 alt=&#34Usage example&#34 type=&#34image/svg+xml&#34></object>
--
--
-- @property handle_border_color
-- @tparam color|nil handle_border_color
-- @propemits true false
-- @propbeautiful

--- The handle border width.
-- @property handle_border_width
-- @tparam[opt=0] number|nil handle_border_width
-- @propertyunit pixel
-- @negativeallowed false
-- @propemits true false
-- @propbeautiful

--- The cursor icon while grabbing the handle.
-- The available cursor names are:
--
--
--
-- @property handle_cursor
-- @tparam[opt="fleur"] string|nil handle_cursor
-- @propbeautiful
-- @see mousegrabber

--- The bar (background) shape.
--
--
--
--<object class=&#34img-object&#34 data=&#34../images/AUTOGEN_wibox_widget_slider_bar_shape.svg&#34 alt=&#34Usage example&#34 type=&#34image/svg+xml&#34></object>
--
--
-- @property bar_shape
-- @tparam shape|nil bar_shape
-- @propemits true false
-- @propbeautiful
-- @see gears.shape

--- The bar (background) height.
--
--
--
--<object class=&#34img-object&#34 data=&#34../images/AUTOGEN_wibox_widget_slider_bar_height.svg&#34 alt=&#34Usage example&#34 type=&#34image/svg+xml&#34></object>
--
--
-- @property bar_height
-- @tparam number|nil bar_height
-- @propertyunit pixel
-- @negativeallowed false
-- @propbeautiful
-- @propemits true false

--- The bar (background) color.
--
--
--
--<object class=&#34img-object&#34 data=&#34../images/AUTOGEN_wibox_widget_slider_bar_color.svg&#34 alt=&#34Usage example&#34 type=&#34image/svg+xml&#34></object>
--
--
-- @property bar_color
-- @tparam color|nil bar_color
-- @propbeautiful
-- @propemits true false

--- The bar (active) color.
--
--
--
--<object class=&#34img-object&#34 data=&#34../images/AUTOGEN_wibox_widget_slider_bar_active_color.svg&#34 alt=&#34Usage example&#34 type=&#34image/svg+xml&#34></object>
--
--
-- Only works when both `bar_active_color` and `bar_color` are passed as hex color string
-- @property bar_active_color
-- @tparam color|nil bar_active_color
-- @propbeautiful
-- @propemits true false

--- The bar (background) margins.
--
--
--
--<object class=&#34img-object&#34 data=&#34../images/AUTOGEN_wibox_widget_slider_bar_margins.svg&#34 alt=&#34Usage example&#34 type=&#34image/svg+xml&#34></object>
--
--
-- @property bar_margins
-- @tparam[opt={}] table|number|nil bar_margins
-- @tparam[opt=0] number bar_margins.left
-- @tparam[opt=0] number bar_margins.right
-- @tparam[opt=0] number bar_margins.top
-- @tparam[opt=0] number bar_margins.bottom
-- @propertyunit pixel
-- @propertytype number A single value used for all sides.
-- @propertytype table A different value for each side. The side names are:
-- @negativeallowed true
-- @propbeautiful
-- @propemits true false

--- The bar (background) border width.
-- @property bar_border_width
-- @tparam[opt=0] number|nil bar_border_width
-- @propertyunit pixel
-- @negativeallowed false
-- @propemits true false
-- @propbeautiful

--- The bar (background) border_color.
--
--
--
--<object class=&#34img-object&#34 data=&#34../images/AUTOGEN_wibox_widget_slider_bar_border.svg&#34 alt=&#34Usage example&#34 type=&#34image/svg+xml&#34></object>
--
--
-- @property bar_border_color
-- @tparam color|nil bar_border_color
-- @propbeautiful
-- @propemits true false

--- The slider value.
--
--
--
--<object class=&#34img-object&#34 data=&#34../images/AUTOGEN_wibox_widget_slider_value.svg&#34 alt=&#34Usage example&#34 type=&#34image/svg+xml&#34></object>
--
--
-- @property value
-- @tparam[opt=0] number value
-- @negativeallowed true
-- @propemits true false

--- The slider minimum value.
--
-- @property minimum
-- @tparam[opt=0] number minimum
-- @negativeallowed true
-- @propemits true false

--- The slider maximum value.
--
-- @property maximum
-- @tparam[opt=100] number maximum
-- @negativeallowed true
-- @propemits true false

--- The bar (background) border width.
--
-- @beautiful beautiful.slider_bar_border_width
-- @param number

--- The bar (background) border color.
--
-- @beautiful beautiful.slider_bar_border_color
-- @param color

--- The handle border_color.
--
-- @beautiful beautiful.slider_handle_border_color
-- @param color

--- The handle border width.
--
-- @beautiful beautiful.slider_handle_border_width
-- @param number

--- The handle width.
--
-- @beautiful beautiful.slider_handle_width
-- @param number

--- The handle color.
--
-- @beautiful beautiful.slider_handle_color
-- @param color

--- The handle shape.
--
-- @beautiful beautiful.slider_handle_shape
-- @tparam[opt=gears.shape.rectangle] gears.shape shape
-- @see gears.shape

--- The cursor icon while grabbing the handle.
-- The available cursor names are:
--
--
--
-- @beautiful beautiful.slider_handle_cursor
-- @tparam[opt="fleur"] string cursor
-- @see mousegrabber

--- The bar (background) shape.
--
-- @beautiful beautiful.slider_bar_shape
-- @tparam[opt=gears.shape.rectangle] gears.shape shape
-- @see gears.shape

--- The bar (background) height.
--
-- @beautiful beautiful.slider_bar_height
-- @param number

--- The bar (background) margins.
--
-- @beautiful beautiful.slider_bar_margins
-- @tparam[opt={}] table margins
-- @tparam[opt=0] number margins.left
-- @tparam[opt=0] number margins.right
-- @tparam[opt=0] number margins.top
-- @tparam[opt=0] number margins.bottom

--- The slider handle margins.
--
-- @beautiful beautiful.slider_handle_margins
-- @tparam[opt={}] table margins
-- @tparam[opt=0] number margins.left
-- @tparam[opt=0] number margins.right
-- @tparam[opt=0] number margins.top
-- @tparam[opt=0] number margins.bottom

--- The bar (background) color.
--
-- @beautiful beautiful.slider_bar_color
-- @param color

--- The bar (active) color.
--
-- Only works when both `beautiful.slider_bar_color` and `beautiful.slider_bar_active_color` are hex color strings
-- @beautiful beautiful.slider_bar_active_color
-- @param color


local properties = {
    -- Handle
    handle_shape         = shape.rectangle,
    handle_color         = false,
    handle_margins       = {},
    handle_width         = false,
    handle_border_width  = 0,
    handle_border_color  = false,
    handle_cursor        = "fleur",

    -- Bar
    bar_shape            = shape.rectangle,
    bar_height           = false,
    bar_color            = false,
    bar_active_color     = false,
    bar_margins          = {},
    bar_border_width     = 0,
    bar_border_color     = false,

    -- Content
    value                = 0,
    minimum              = 0,
    maximum              = 100,
}

-- Create the accessors
for prop in pairs(properties) do
    slider["set_"..prop] = function(self, value)
        local changed = self._private[prop] ~= value
        self._private[prop] = value

        if changed then
            self:emit_signal("property::"..prop, value)
            self:emit_signal("widget::redraw_needed")
        end
    end

    slider["get_"..prop] = function(self)
        -- Ignoring the false's is on purpose
        return self._private[prop] == nil
            and properties[prop]
            or self._private[prop]
    end
end

-- Add some validation to set_value
function slider:set_value(value)
    value = math.min(value, self:get_maximum())
    value = math.max(value, self:get_minimum())
    local changed = self._private.value ~= value

    self._private.value = value

    if changed then
        self:emit_signal( "property::value", value)
        self:emit_signal( "widget::redraw_needed" )
    end
end

local function get_extremums(self)
    local min = self._private.minimum or properties.minimum
    local max = self._private.maximum or properties.maximum
    local interval = max - min

    return min, max, interval
end

function slider:draw(_, cr, width, height)
    local value = self._private.value or self._private.min or 0

    local maximum = self._private.maximum
        or properties.maximum

    local minimum = self._private.minimum
        or properties.minimum

    local range = maximum - minimum
    local active_rate = (value - minimum) / range

    local handle_height, handle_width = height, self._private.handle_width
        or beautiful.slider_handle_width
        or math.floor(height/2)

    local handle_border_width = self._private.handle_border_width
        or beautiful.slider_handle_border_width
        or properties.handle_border_width or 0

    local bar_height = self._private.bar_height

    -- If there is no background, then skip this
    local bar_color = self._private.bar_color
        or beautiful.slider_bar_color

    local bar_active_color = self._private.bar_active_color
        or beautiful.slider_bar_active_color

    if bar_color then
        cr:set_source(color(bar_color))
    end

    local margins = self._private.bar_margins
        or beautiful.slider_bar_margins

    local x_offset, right_margin, y_offset = 0, 0

    if margins then
        if type(margins) == "number" then
            bar_height = bar_height or (height - 2*margins)
            x_offset, y_offset = margins, margins
            right_margin = margins
        else
            bar_height = bar_height or (
                height - (margins.top or 0) - (margins.bottom or 0)
            )
            x_offset, y_offset = margins.left or 0, margins.top or 0
            right_margin = margins.right or 0
        end
    else
        bar_height = bar_height or beautiful.slider_bar_height or height
        y_offset   = math.floor((height - bar_height)/2)
    end


    cr:translate(x_offset, y_offset)

    local bar_shape = self._private.bar_shape
        or beautiful.slider_bar_shape
        or properties.bar_shape

    local bar_border_width = self._private.bar_border_width
        or beautiful.slider_bar_border_width
        or properties.bar_border_width

    bar_shape(cr, width - x_offset - right_margin, bar_height or height)

    if bar_active_color and type(bar_color) == "string" and type(bar_active_color) == "string" then
        local bar_active_width = math.floor(
            active_rate * (width - x_offset - right_margin)
            - (handle_width - handle_border_width/2) * (active_rate - 0.5)
        )
        cr:set_source(color.create_pattern{
            type        = "linear",
            from        = {0,0},
            to          = {bar_active_width, 0},
            stops       = {{0.99, bar_active_color}, {0.99, bar_color}}
        })
    end

    if bar_color then
        if bar_border_width == 0 then
            cr:fill()
        else
            cr:fill_preserve()
        end
    end

    -- Draw the bar border
    if bar_border_width > 0 then
        local bar_border_color = self._private.bar_border_color
            or beautiful.slider_bar_border_color
            or properties.bar_border_color

        cr:set_line_width(bar_border_width)

        if bar_border_color then
            cr:save()
            cr:set_source(color(bar_border_color))
            cr:stroke()
            cr:restore()
        else
            cr:stroke()
        end
    end

    cr:translate(-x_offset, -y_offset)

    -- Paint the handle
    local handle_color = self._private.handle_color
        or beautiful.slider_handle_color

    -- It is ok if there is no color, it will be inherited
    if handle_color then
        cr:set_source(color(handle_color))
    end

    local handle_shape = self._private.handle_shape
        or beautiful.slider_handle_shape
        or properties.handle_shape

    -- Lets get the margins for the handle
    margins = self._private.handle_margins
        or beautiful.slider_handle_margins

    x_offset, y_offset = 0, 0

    if margins then
        if type(margins) == "number" then
            x_offset, y_offset = margins, margins
            handle_width  = handle_width  - 2*margins
            handle_height = handle_height - 2*margins
        else
            x_offset, y_offset = margins.left or 0, margins.top or 0
            handle_width  = handle_width  -
                (margins.left or 0) - (margins.right  or 0)
            handle_height = handle_height -
                (margins.top  or 0) - (margins.bottom or 0)
        end
    end

    -- Get the widget size back to it's non-transfored value
    local min, _, interval = get_extremums(self)
    local rel_value = math.floor(((value-min)/interval) * (width-handle_width))

    cr:translate(x_offset + rel_value, y_offset)

    handle_shape(cr, handle_width, handle_height)

    if handle_border_width > 0 then
        cr:fill_preserve()
    else
        cr:fill()
    end

    -- Draw the handle border
    if handle_border_width > 0 then
        local handle_border_color = self._private.handle_border_color
            or beautiful.slider_handle_border_color
            or properties.handle_border_color

        if handle_border_color then
            cr:set_source(color(handle_border_color))
        end

        cr:set_line_width(handle_border_width)
        cr:stroke()
    end
end

function slider:fit(_, width, height)
    -- Use all the space, this should be used with a constraint widget
    return width, height
end

-- Move the handle to the correct location
local function move_handle(self, width, x, _)
    local min, _, interval = get_extremums(self)
    self:set_value(min+math.floor((x*interval)/width))
end

local function mouse_press(self, x, y, button_id, _, geo)
    if button_id ~= 1 then return end

    local matrix_from_device = geo.hierarchy:get_matrix_from_device()

    -- Sigh. geo.width/geo.height is in device space. We need it in our own
    -- coordinate system
    local width = geo.widget_width

    move_handle(self, width, x, y)

    -- Calculate a matrix transforming from screen coordinates into widget coordinates
    local wgeo = geo.drawable.drawable:geometry()
    local matrix = matrix_from_device:translate(-wgeo.x, -wgeo.y)

    local handle_cursor = self._private.handle_cursor
        or beautiful.slider_handle_cursor
        or properties.handle_cursor

    capi.mousegrabber.run(function(mouse)
        if not mouse.buttons[1] then
            return false
        end

        -- Calculate the point relative to the widget
        move_handle(self, width, matrix:transform_point(mouse.x, mouse.y))

        return true
    end,handle_cursor)
end

--- Create a slider widget.
--
-- @constructorfct wibox.widget.slider
-- @tparam[opt={}] table args
-- @tparam[opt] gears.shape args.handle_shape The slider handle shape.
-- @tparam[opt] color args.handle_color The slider handle color.
-- @tparam[opt] table args.handle_margins The slider handle margins.
-- @tparam[opt] number args.handle_width The slider handle width.
-- @tparam[opt] color args.handle_border_color The handle border_color.
-- @tparam[opt] number args.handle_border_width The handle border width.
-- @tparam[opt] string args.handle_cursor
--   The cursor icon while grabbing the handle.
--   The available cursor names are listed under handle_cursor, in the "Object properties" section.
-- @tparam[opt] gears.shape args.bar_shape The bar (background) shape.
-- @tparam[opt] number args.bar_height The bar (background) height.
-- @tparam[opt] color args.bar_color The bar (background) color.
-- @tparam[opt] color args.bar_active_color The bar (active) color.
-- @tparam[opt] table args.bar_margins The bar (background) margins.
-- @tparam[opt] number args.bar_border_width The bar (background) border width.
-- @tparam[opt] color args.bar_border_color The bar (background) border_color.
-- @tparam[opt] number args.value The slider value.
-- @tparam[opt] number args.minimum The slider minimum value.
-- @tparam[opt] number args.maximum The slider maximum value.
local function new(args)
    local ret = base.make_widget(nil, nil, {
        enable_properties = true,
    })

    gtable.crush(ret._private, args or {})

    gtable.crush(ret, slider, true)

    ret:connect_signal("button::press", mouse_press)

    return ret
end

function slider.mt:__call(...)
    return new(...)
end

return setmetatable(slider, slider.mt)

-- vim: filetype=lua:expandtab:shiftwidth=4:tabstop=8:softtabstop=4:textwidth=80
