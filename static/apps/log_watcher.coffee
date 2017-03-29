log_watcher =
    version: '0.1'
    lscache_templates: env.is_minified
_register_module('log_watcher', log_watcher)

base_url = "/static/apps/ractive_templates/"
log_watcher.templates = _load_templates({
    log_watcher: "#{base_url}log_watcher.html"
    chain_view: "#{base_url}chain_view.html"
    log_table: "#{base_url}log_table.html"
    all_entries_view: "#{base_url}all_entries_view.html"
}, 'log_watcher', log_watcher.version, log_watcher.lscache_templates)

log_watcher.ready = [
    log_watcher.templates
]


$.when(log_watcher.ready...).then (templates) ->

    LogTable = Ractive.extend
        template: templates.log_table
        isolated: true
        data:
            entries: null
            milliseconds: (s) -> (s * 1000).toFixed(2)
            color_for_code: (code) ->
                return 'green' if 100 <= code < 400
                return 'pink' if 400 <= code < 500
                return 'red' if 500 <= code < 600

            bytes_to_str: (b) ->
                return "#{b} B" if b < 1024
                return "#{(b / 1024).toFixed(1)} KB" if b < Math.pow(1024, 2)
                return "#{(b / Math.pow(1024, 2)).toFixed(3)} МB" if b < Math.pow(1024, 3)
                
            entry_to_str: (entry) -> JSON.stringify(entry, null, '  ')
            uuid_short: (uuid) -> uuid.substr(0, 5)
            uuid_link: (uuid) -> "#?uuid=#{uuid}&tab=chain"

        oninit: ->
            @on 'expand-entry-click', (e) -> e.toggle('expanded')
            @on 'entry-click', (e) -> @fire('uuid-selected', e.get('data.log_uuid'))
            @on 'entry-user-click', (e) -> @fire('user-selected', e.get('data.request.user.id'))
            @on 'request-path-click', (e) -> @fire('request-path-selected', e.get('data.request.path'), e.get('data.request.method'))
            @on 'response-code-click', (e) -> @fire('resp-code-selected', e.get('data.response.code'))
            @on 'response-code-hover', (e) ->
                if not e.node.title
                    e.node.title = JSON.stringify(e.get('data.response.json'))



    AllEntriesView = Ractive.extend
        template: templates.all_entries_view
        isolated: true
        data:
            entries: null
            loaded: false
            loading: false
            collections: null
            filters: null

        load_table: (continuous = false) ->
            return if @get('loading')
            @set('loading', true)
            continuous = false if not @get('loaded')

            args =
                collection: @get('collections')
                limit: @get_pages_size()

            if filters = @get('filters')
                args.filters_str = JSON.stringify(filters)

            if continuous
                args.skip = (@count_per_collection[c] for c in @get('collections'))

            $.getJSON url("logs_list") + '?' + $.param(args, true), (result) =>
                if not continuous      # обнуляем все параметры при "чистой" загрузке
                    @set('entries', [])
                    @scroll_container.scrollTop = 0
                    @count_per_collection = {}

                    for c in @get('collections')
                        @count_per_collection[c] = 0

                for entry in result
                    entry.expanded = false  # для отображения в таблице в свернутом состоянии
                    @push('entries', entry)
                    @count_per_collection[entry.collection] += 1

                @set
                    loading: false
                    loaded: true

                @last_result_count = result.length

        get_pages_size: -> Math.max(Math.ceil(@scroll_container.clientHeight / 30), 10)

        container_scroll: ->
            el = @scroll_container
            @load_table(true) if not @get('loading') and
                                 @last_result_count and
                                 el.scrollHeight - el.clientHeight - el.scrollTop < 20

        oncomplete: ->
            @observe 'collections filters', -> @load_table()

        onrender: ->
            @scroll_container = document.body
            window.onscroll = (e) => @container_scroll()



    ChainView = Ractive.extend
        template: templates.chain_view
        isolated: true
        data:
            uuid: null
            collections: null
            entries: null
            loading: false

        load_chain: ->
            uuid = @get('uuid')
            return if not uuid or @get('loading')
            @set('loading', true)

            args =
                collection: @get('collections')

            $.getJSON url("logs_by_uuid", uuid) + '?' + $.param(args, true), (result) =>
                for entry in result
                    entry.expanded = false  # для отображения в таблице в свернутом состоянии
                @set
                    entries: result
                    loading: false

        onrender: ->
            @observe 'uuid collections', -> @load_chain()


    LogWatcher = Ractive.extend
        template: templates.log_watcher
        isolated: true
        data:
            collections: null
            opened_tabs: null
            active_tab: null
            selected_uuid: null
            sidebar_visible: true
            filters: null
            filters_str: null
            filters_str_valid: true

        computed:
            active_collections: -> c.name for c in @get('collections') when c.is_active

        reset_collections: ->
            collections = []
            for i in env.collections
                collections.push
                    name: i
                    is_active: true

            @set('collections', collections)

        set_collections_from_hash: ->
            values = _getQueryValue('collections', window.location.hash)
            return if values == undefined

            values = values.split(',')
            changed = false
            for c in @get('collections')
                new_val = values.indexOf(c.name) != -1
                if c.is_active != new_val
                    changed = true
                c.is_active = new_val

            if changed
                @update('collections')

        set_active_tab_from_hash: ->
            tab = _getQueryValue('tab', window.location.hash)
            if not tab?.length
                tab = $('#log-tabs .item')[0].dataset.tab

            @set_active_tab(tab)

        set_uuid_from_hash: ->
            uuid = _getQueryValue('uuid', window.location.hash) or null
            @set('selected_uuid', uuid)

        set_filters_from_hash: ->
            filters = _getQueryValue('filters', window.location.hash) or ''
            @set('filters_str', filters)

        set_active_tab: (tab) ->
            return if @get('active_tab') == tab
            $("#log-tabs .item[data-tab=#{tab}]").click()
            @set('active_tab', tab)

        update_url_hash: ->
            d = {}
            d.collections = @get('active_collections').join(',')
            d.tab = @get('active_tab')

            if uuid = @get('selected_uuid')
                d.uuid = uuid

            if filters = @get('filters_str')
                d.filters = filters

            window.location.hash = '?' + $.param(d)

        read_url_hash_params: ->
            @set_collections_from_hash()
            @set_active_tab_from_hash()
            @set_uuid_from_hash()
            @set_filters_from_hash()

        show_chain: (uuid) ->
            return if not uuid or uuid == @get('selected_uuid')
            @set('selected_uuid', uuid)
            @set_active_tab('chain')
            @update_url_hash()

        set_filter: (obj) ->
            filters = @get('filters')
            _extend(filters, obj)
            @set('filters_str', JSON.stringify(filters))
#            @update('filters')
            @update_url_hash()

        oncomplete: ->
            $('.menu .item').tab()
            @read_url_hash_params()
            @update_url_hash()

        oninit: ->
            @reset_collections()
            @set('opened_tabs', {})
            @set('filters', {})
            document.title = 'Log watcher'

            window.onhashchange = (e) => @read_url_hash_params()

            @observe 'active_tab', (val) ->
                return if not val
                @set("opened_tabs.#{val}", true) # запоминает открытые вкладки

            @observe 'filters_str', (str) ->
                if not str?.length
                    @set
                        filters: {}
                        filters_str_valid: true
                    return
                try
                    val = JSON.parse(str)
                    @set
                        filters: val
                        filters_str_valid: true
                    @update_url_hash()
                catch SyntaxError
                    @set('filters_str_valid', false)

            @on '*.uuid-selected', (uuid) -> @show_chain(uuid)

            @on '*.user-selected', (user_id) -> @set_filter({'data.request.user.id': user_id})
            @on '*.resp-code-selected', (resp_code) -> @set_filter({'data.response.code': resp_code})
            @on '*.request-path-selected', (path, method) -> @set_filter({'data.request.path': path, 'data.request.method': method})

            @on 'sidebar-toggle-click', -> @toggle('sidebar_visible')

            @on 'collection-click', (e) ->
                e.toggle('is_active')
                @update_url_hash()

            @on 'tab-click', (e) ->
                tab = e.node.dataset.tab
                @set('active_tab', tab)
                @update_url_hash()


    Ractive.components.LogTable = LogTable
    Ractive.components.AllEntriesView = AllEntriesView
    Ractive.components.ChainView = ChainView
    Ractive.components.LogWatcher = LogWatcher
