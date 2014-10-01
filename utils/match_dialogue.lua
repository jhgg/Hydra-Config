local fnutils = require 'mjolnir.fnutils'
local utf8 = require('mjolnir._asm.data').utf8

local fuzzy_matcher = import('utils/matchers/fuzzy')
local contains_matcher = import('utils/matchers/contains')
local combinator = import('utils/matchers/combinator')

local default_opts = {
    -- Matching functions
    matching_fn = combinator(contains_matcher.match, fuzzy_matcher.match),
    scoring_fn = fuzzy_matcher.score,

    -- Hookable functions
    before_grid_init_fn = nil, -- Called before the textgrid is initialized for the first time.
    after_grid_init_fn = nil, -- Called after the textgrid is initialized for the first time.

    before_grid_show_fn = nil, -- Called before the grid is shown.
    after_grid_show_fn = nil, -- Called after the grid is shown.

    before_grid_hide_fn = nil, -- Called before the grid is hidden.
    after_grid_hide_fn = nil, -- Called after the grid is hidden.

    keydown_override_fn = nil, -- Called before any keydown process is hiding. Return true to stop propegation of event.

    -- Colors (Text)
    matched_color = "00FF00",
    matched_color_faded = "248F24",
    no_match_color = "FF0000",

    -- Colors (Window)
    background_color = "222222",

    -- Fonts
    font_face = "Menlo",
    font_size = 32,

    -- Other
    matcher_window_width = 64
}

local match_dialogue__proto = {}
local match_dialogue__keyhandlers = {}
local match_dialogue__mt = { __index = match_dialogue__proto }

local function match_dialogue_new(data_source_fn, match_selected_fn, opts)
    local matcher = {}
    setmetatable(matcher, match_dialogue__mt)
    return matcher:init(data_source_fn, match_selected_fn, opts)
end

function match_dialogue__proto:init(data_source_fn, match_selected_fn,  opts)
    if type(data_source_fn) ~= "function" then
        error("data_source_fn (paramater 0) must be a function!")
    end

    if type(match_selected_fn) ~= "function" then
        error("match_selected_fn (paramater 0) must be a function!")
    end

    if opts == nil then
        opts = {}
    end
    for k, v in pairs(default_opts) do
        if opts[k] == nil then
            opts[k] = v
        end
    end

    self.opts = opts
    self.data_source_fn = data_source_fn
    self.match_selected_fn = match_selected_fn
    self.input_chars = {}
    self.charbuf = {}
    self.drawbuf = {}
    self.matches = {}
    self.data_to_match = nil

    return self
end

function match_dialogue__proto:__maybe_call_fn(fn, ...)
    if self.opts[fn] ~= nil then
        return self.opts[fn](self, ...)
    end
end

function match_dialogue__proto:get_textgrid_singleton()
    if self.__text_grid == nil then
        self:__maybe_call_fn('before_grid_init_fn')
        self.__text_grid = self:__init_text_grid()
        self:__maybe_call_fn('after_grid_init_fn', self.__text_grid)

    end
    return self.__text_grid
end

function match_dialogue__proto:show()
    local grid = self:get_textgrid_singleton()
    self:__maybe_call_fn('before_grid_show_fn', grid)
    self.charbuf = {}
    self:clear_drawbuf()
    self:__redraw()

    grid:show()
    grid:window():focus()

    self:__maybe_call_fn('after_grid_show_fn', grid)
end

function match_dialogue__proto:hide()
    local grid = self:get_textgrid_singleton()
    self:__maybe_call_fn('before_grid_hide_fn', grid)
    self.charbuf = {}
    self.matches = {}
    self.data_to_match = nil
    self.current_match_index = nil

    grid:hide()

    self:__maybe_call_fn('after_grid_hide_fn', grid)
end

function match_dialogue__proto:__init_text_grid()
    local grid = textgrid.create()

    grid:sethasshadow(false)
    grid:sethastitlebar(false)
    grid:setbg(self.opts.background_color)
    grid:usefont(self.opts.font_face, self.opts.font_size)
    grid:resize({
        w = self.opts.matcher_window_width,
        h = 1
    })
    grid:keydown(fnutils.partial(self.__text_grid_keydown, self))
    grid:center()

    return grid
end

function match_dialogue__proto:__text_grid_keydown(e)
    if self:__maybe_call_fn('keydown_override_fn', e) then
        return
    end

    local handler = match_dialogue__keyhandlers[e.key]
    if handler == nil then
        handler = match_dialogue__keyhandlers.insert_char
    end

    handler(self, e)
end

function match_dialogue__proto:__redraw()
    if self.__text_grid == nil then return end

    local win = self.__text_grid
    win:clear()
    local y = 1

    for x = 1, math.min(#self.drawbuf, self.opts.matcher_window_width) do
        local char = self.drawbuf[x]
        win:setchar(char.char, x, y)
        if char.fg then
            win:setcharfg(char.fg, x, y)
        end
        if char.bg then
            win:setcharbg(char.bg, x, y)
        end
    end
end

function match_dialogue__proto:update()
    if self.data_to_match == nil then
        self.data_to_match = self.data_source_fn()
    end

    local matches = self:match_and_score(table.concat(self.charbuf))
    table.sort(matches, function(a, b)
        return a.score < b.score
    end)

    if #matches > 0 then
        self.current_match_index = 1
        self.matches = matches
        self:fill_drawbuf_with_current_match()
    else
        self.matches = nil
        self.current_match_index = nil
        self:fill_drawbuf_with_buf_and_color(self.charbuf, self.opts.no_match_color)
    end

    self:__redraw()
end

function match_dialogue__proto:match_and_score(needle)
    local matches = {}
    needle = utf8.chars(needle:lower())

    for _, data in ipairs(self.data_to_match) do

        if data._haystack_utf8 == nil then
            data._haystack_utf8 = utf8.chars(data.string:lower())
        end

        local match_indexes = self.opts.matching_fn(needle, data._haystack_utf8)

        if match_indexes ~= nil and #match_indexes > 0 then
            local score = self.opts.scoring_fn(needle, data.string, match_indexes)
            table.insert(matches, {
                data = data,
                match_indexes = match_indexes,
                score = score
            })
        end
    end

    return matches
end

function match_dialogue__proto:clear_drawbuf()
    local tab = self.drawbuf
    for k in pairs(tab) do tab[k] = nil end
end

function match_dialogue__proto:fill_drawbuf_with_current_match()
    self:clear_drawbuf()
    local match = self.matches[self.current_match_index]
    local chars = utf8.chars(match.data.string)

    for i = 1, #chars do
        table.insert(self.drawbuf, {
            char = chars[i],
            fg = self.opts.matched_color_faded
        })
    end

    for _, i in ipairs(match.match_indexes) do
        self.drawbuf[i].fg = self.opts.matched_color
    end
end

function match_dialogue__proto:fill_drawbuf_with_buf_and_color(buf, fg, bg)
    self:clear_drawbuf()
    for _, char in ipairs(buf) do
        table.insert(self.drawbuf, {
            char = char,
            fg = fg,
            bg = bg
        })
    end
end

function match_dialogue__keyhandlers:insert_char(e)
    if #self.charbuf >= self.opts.matcher_window_width then return end
    if #e.key ~= 1 then return end

    self.charbuf[#self.charbuf + 1] = e.key
    self:update()
end

function match_dialogue__keyhandlers:delete()
    if #self.charbuf >= self.opts.matcher_window_width then return end
    self.charbuf[#self.charbuf] = nil
    self:update()
end

function match_dialogue__keyhandlers:up()
    if self.matches and #self.matches then
        self.current_match_index = self.current_match_index + 1
        if self.current_match_index > #self.matches then
            self.current_match_index = 1
        end
        self:fill_drawbuf_with_current_match()
        self:__redraw()
    end
end

function match_dialogue__keyhandlers:down()
    if self.matches and #self.matches then
        self.current_match_index = self.current_match_index - 1
        if self.current_match_index < 1 then
            self.current_match_index = #self.matches
        end
        self:fill_drawbuf_with_current_match()
        self:__redraw()
    end
end

function match_dialogue__keyhandlers:escape()
    self:hide()
end

function match_dialogue__keyhandlers:return_()
    if self.matches and #self.matches then
        self.match_selected_fn(self.matches[self.current_match_index].data)
        self:hide()
    end

end

match_dialogue__keyhandlers['return'] = match_dialogue__keyhandlers.return_
match_dialogue__keyhandlers["\x1b"] = match_dialogue__keyhandlers.escape

return match_dialogue_new
