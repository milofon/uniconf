/**
 * SDLang Loader
 *
 * Copyright: (c) 2015-2018, Milofon Project.
 * License: Subject to the terms of the BSD 3-Clause License, as written in the included LICENSE.md file.
 * Author: <m.galanin@milofon.pro> Maksim Galanin
 * Date: 2018-09-03
 */

module uniconf.sdlang;

private
{
    import std.array : empty;

    import sdlang;

    import uniconf.core.loader;
    import uniconf.core.exception;
}


/**
 * The loader data from a SDLang file
 */
class SdlangConfigLoader : LangConfigLoader
{
    /**
     * Load config from file
     */
    Config loadConfigFile(string fileName)
    {
        Tag root;

        try
            root = parseFile(fileName);
        catch(ParseException e)
            throw new ConfigException("Error loading sdlang from a file '"
                    ~ fileName ~ "':", e.file, e.line, e);

        return toConfig(root);
    }

    /**
     * Load config from string
     */
    Config loadConfigString(string data)
    {
        Tag root;

        try
            root = parseSource(data);
        catch(ParseException e)
            throw new ConfigException("Error loading sdlang from string:",
                    e.file, e.line, e);

        return toConfig(root);
    }


    string[] getExtensions()
    {
        return [".sdl"];
    }


    private Config toConfig(Tag root)
    {
        Config convertVal(Value val)
        {
            if (val.convertsTo!bool)
                return Config(val.get!bool);
            else if (val.convertsTo!long)
                return Config(val.get!long);
            else if (val.convertsTo!string)
                return Config(val.get!string);
            else if (val.convertsTo!double)
                return Config(val.get!double);
            else
                return Config();
        }

        Config convert(Tag tag)
        {
            if (!tag.tags.empty || !tag.attributes.empty)
            {
                Config[string] map;
                if (!tag.values.empty && tag.values[0].convertsTo!string)
                    map["name"] = convertVal(tag.values[0]);

                if (!tag.attributes.empty)
                    foreach(Attribute a; tag.attributes)
                        map[a.name] = convertVal(a.value);

                if (!tag.tags.empty)
                    foreach(Tag sub; tag.tags)
                    {
                        Config res = convert(sub);

                        if (auto subConf = sub.name in map)
                        {
                            if (subConf.kind == Config.Kind.array)
                                *subConf ~= res;
                            else
                                map[sub.name] = Config([*subConf, res]);
                        }
                        else
                            map[sub.name] = res;
                    }

                return Config(map);
            }
            else if (tag.values.length == 1)
            {
                return convertVal(tag.values[0]);
            }
            else if (tag.values.length > 0)
            {
                Config[] arr;
                foreach (Value v; tag.values)
                    arr ~= convertVal(v);
                return Config(arr);
            }
            else
                return Config();
        }

        return convert(root);
    }
}



@system unittest
{
    auto loader = new SdlangConfigLoader();
    auto conf = loader.loadConfigString(`
logger "console" {
    appender "console"
    level "debugv"
    name "sdf"
}
`);

    assert("logger.name" in conf);
    assert("logger.level" in conf);
    assert(conf.getArray("logger.name").length == 2);
    assert(conf.get!string("logger.level") == "debugv");
}

