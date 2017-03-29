TIMERS =
    one_shot: {}
    periodic: {}


@csrfSafeMethod = (method) -> (/^(GET|HEAD|OPTIONS|TRACE)$/.test(method))


@uniqueId = (length=8) ->
  id = ""
  id += Math.random().toString(36).substr(2) while id.length < length
  id.substr 0, length


@make_timer = (options) ->
    o =
        callback: ->
        timeout: 1000
        name: '000'
        one_shot: false
    o = _extend(o, options)

    if options.one_shot
        clear_timer(o.name, true)
        timer_id = window.setTimeout(o.callback, o.timeout)
        TIMERS.one_shot[o.name] = timer_id
    else
        clear_timer(o.name, false)
        timer_id = window.setInterval(o.callback, o.timeout)
        TIMERS.periodic[o.name] = timer_id

    return timer_id


@clear_timer = (name, one_shot) ->
    if one_shot and name of TIMERS.one_shot
        timer_id = TIMERS.one_shot[name]
        window.clearTimeout(timer_id)
        delete TIMERS.one_shot[name]
    else if not one_shot and name of TIMERS.periodic
        timer_id = TIMERS.periodic[name]
        window.clearInterval(timer_id)
        delete TIMERS.periodic[name]


@clear_timers = ->
    clear_timer(t, true) for t, val of TIMERS.one_shot
    clear_timer(t) for t, val of TIMERS.periodic


@_debounce = (key, timeout, callback) ->
    clear_timer(key, true)
    make_timer
        name: key
        timeout: timeout
        one_shot: true
        callback: callback


@_obj2hash = (obj) ->
    return encodeURIComponent(JSON.stringify(obj))


@_hash2obj = (str) ->
    return JSON.parse(decodeURIComponent(str))


@_extend = (dst, src_list..., exclude=[]) ->
    if exclude not instanceof Array
        src_list.push(exclude)
        exclude = []
    for src in src_list
        dst[key] = value for own key, value of src when key not in exclude
    return dst

@_int = (value, min = 0, max = undefined) ->
    value = +value
    return min if not value or typeof value != 'number' or value < min
    return max if value > max
    return Math.floor(value)

@_getQueryValue = (param, u = document.location.href) ->
    i = u.indexOf '?'
    if i < 0 then return
    query = u.substr(i+1)
    vars = query.split('&')
    for part in vars
        pair = part.split('=');
        if decodeURIComponent(pair[0]) == param
            return decodeURIComponent(pair[1])


@gettext_gender = (male_text, fem_text, neuter_text, detection_text) ->
    detection_char = _.last(_.words(detection_text)[0])   # берем последнюю букву первого слова
    return fem_text if detection_char in 'ая'
    return neuter_text if detection_char == 'о'
    return male_text


@_error = (message, display_length=4000) ->
    UIkit.notify({message: message, status: 'danger', timeout: display_length})


@_success = (message, display_length=4000) ->
    UIkit.notify({message: message, status: 'success', timeout: display_length})


@_warning = (message, display_length=4000) ->
    UIkit.notify({message: message, status: 'warning', timeout: display_length})


@_info = (message, display_length=4000) ->
    UIkit.notify(message, {timeout: display_length})


@_ajaxError = (jqXHR, display_length=4000) ->
    data = jqXHR.responseJSON?.detail or jqXHR.responseJSON or "#{jqXHR.status}: #{jqXHR.statusText}"
    return _error(data, display_length)


@_confirm_dialog = (options) ->      # content, url, method, success, message
    content = options.content or ''
    modal_options =
        bgclose: true
        keyboard: true
        labels:
            'Cancel': gettext('Cancel')

    request = =>
        $.ajax
            url: options.url
            method: options.method or 'GET'
            success: =>
                if options.message then _success options.message
                options.success()

            error: (res) -> _ajaxError(res)

    if options.skip_dialog
        request()
    else
        UIkit.modal.confirm content, request, null, modal_options


@_input_dialog = (options) ->      # message, success
    modal_options =
        bgclose: true
        keyboard: true
        labels:
            'Ok': 'Ok'
            'Cancel': gettext('Cancel')

    UIkit.modal.prompt options.message, '', (val) ->
        options.success(val)
    , modal_options


@_load_templates = (urls_dict, namespace, version, cache=true) ->
    lscache.setBucket("templates:#{namespace}:#{version}")
    def_list = []
    url_alias_list = []
    for alias, url of urls_dict
        url_alias_list.push(alias)
        cached_template = lscache.get(alias)
        template_defer = if cached_template and cache then [cached_template] else $.get(url)
        def_list.push(template_defer)

    main_def = $.Deferred()
    w = $.when.apply($, def_list)
    w.then ->
        lscache.setBucket("templates:#{namespace}:#{version}")
        results = {}
        if def_list.length == 1
            template = arguments[0]
            if typeof template == 'object' then template = template[0]  # в случае с кэшируемым шаблоном template_defer - массив (см. выше)
            results[url_alias_list[0]] = template
            lscache.set(url_alias_list[0], template)
        else
            for arg, i in arguments
                break if i > url_alias_list.length
                results[url_alias_list[i]] = arg[0]
                lscache.set(url_alias_list[i], arg[0])

        main_def.resolve(results)

    w.fail -> main_def.reject("Failed to load some of #{urls_dict}")

    return main_def.promise()


@_register_module = (name, module_data) ->
    window.__MODULES__ = {} if not window.__MODULES__
    window.__MODULES__[name] = module_data


@_get_module = (name) ->
    return window.__MODULES__[name]


@strip_tags = (html) -> html.replace(/(<[^>]+>)/ig, "")


@_get_scrollbar_width = ->
    $outer = $('<div>').css({width: 100, height: 100, overflow: 'auto', position: 'absolute', top: -1000, left: -1000}).appendTo('body')
    widthWithScroll = $('<div>').css({width: '100%', height: 200}).appendTo($outer).outerWidth()
    $outer.remove()
    return 100 - widthWithScroll

@_align_to_scrollbar = (elem) -> elem.css('margin-right', "#{_get_scrollbar_width()}px")


String::capFirst = -> @[0].toUpperCase() + @slice(1)

String::capitalize = -> _.capitalize(@)

if typeof String::startsWith != 'function' then String::startsWith = (str) -> @substring(0, str.length) is str

if typeof String::endsWith != 'function' then String::endsWith = (str) -> @substring(@length - str.length, @length) is str

@from_iso_date = (d) -> if not d? then d else new Date(d).toLocaleString()