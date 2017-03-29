from app import app, manager


js_urls_template = r"""
{% autoescape off %}
(function(globals) {
  var django = globals.django || (globals.django = {});

  django.urls = {{ urls_str }};

  django.url = function(url_name, args) {
    var url = django.urls[url_name];

    if (!url) {
      return undefined;
    }

    if (args === undefined) {
        return url;
    }

    if ($.isArray(args)) {
        return url_from_array(name, url, args);
    }
    else if ($.isPlainObject(args)) {
        return url_from_object(name, url, args);
    }
    else {
        var argsArray = Array.prototype.slice.apply(arguments, [1, arguments.length]);
        return url_from_array(name, url, argsArray);
    }
  };

  var token_regex = /<\w*>/g;

  function url_from_array (name, pattern, array) {
    var matches = pattern.match(token_regex),
        parts = pattern.split(token_regex),
        url = parts[0];

    if (!matches && array.length === 0) {
        return url;
    }

    if (matches && matches.length != array.length) {
        console.error('Wrong number of argument for pattern "' + name + '"');
    }

    for (var idx=0; idx < array.length; idx++) {
        url += array[idx] + parts[idx + 1];
    }

    return url;
  }

  function url_from_object (name, pattern, object) {
    var url = pattern,
        tokens = pattern.match(token_regex);

    if (!tokens) {
        return url;
    }

    for (var idx=0; idx < tokens.length; idx++) {
        var token = tokens[idx],
            prop = token.slice(1, -1),
            value = object[prop];

        if (value === undefined) {
            throw new DjangoJsError('Property "' + prop + '" not found');
        }

        url = url.replace(token, value);
    }

    return url;
  }

  /* add to global namespace */
  globals.url = django.url;

}(this));
{% endautoescape %}
"""


@manager.command
def generate_js_urls():
    d = get_urls_dict()

    fpath = app.config['COMPILED_JS_URLS_FILE']
    f = open(fpath, 'w')
    f.write(render_js_urls(d))
    f.close()
    print('written %s' % fpath)


def get_urls_dict():
    """
    Возвращает словарь со всеми url адресами проекта.
    :return: dict, с ключами названиями url, и значениями - шаблонами этих url.

    command_obj.get_urls_dict() -> {
        'resource-detail': '/api/v1/resource/<pk>/',
        'rosetta-reference-selection': '/rosetta/select-ref/<langid>/',
        'resourcetag-list': '/api/v1/resourcetag/'
        ...
    }
    """
    d = {}
    for name, rule in app.url_map._rules_by_endpoint.items():
        d[name] = rule[0].rule
    return d


def render_js_urls(data):
    """
    Рендерит js файл.
    :param data: dict, с ключами названиями url, и значениями - шаблонами этих url.
    :return: str, скомпилированный js файл строкой.
    """
    from jinja2 import Template
    import json

    template = Template(js_urls_template)
    indent = lambda s: s.replace('\n', '\n  ')
    context = {
        'urls_str': indent(json.dumps(data, sort_keys=True, indent=2))
    }
    return template.render(**context)
