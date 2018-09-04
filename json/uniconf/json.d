/**
 * JSON Loader
 *
 * Copyright: (c) 2015-2018, Milofon Project.
 * License: Subject to the terms of the BSD 3-Clause License, as written in the included LICENSE.md file.
 * Author: <m.galanin@milofon.pro> Maksim Galanin
 * Date: 2018-09-03
 */

module uniconf.json;

private
{
    import std.file : FileException, readText;
    import std.json;

    import uniconf.core.loader;
    import uniconf.core.exception;
}


/*
 * The loader data from a JSON file
 */
class JsonConfigLoader : ConfigLoader
{
    Config loadConfigFile(string fileName)
    {
        try
        {
            string source = readText(fileName);
            return loadConfigString(source);
        }
        catch (FileException e)
            throw new ConfigException("Error loading json from a file '"
                    ~ fileName ~ "':", e.file, e.line, e);
    }


    Config loadConfigString(string data)
    {
        JSONValue root;
        try
            root = parseJSON(data);
        catch (JSONException e)
            throw new ConfigException("Error loading json from a string:",
                    e.file, e.line, e);

        return toConfig(root);
    }


    string[] getExtensions()
    {
        return [".json"];
    }


    private Config toConfig(JSONValue root)
    {
        Config convert(JSONValue node)
        {
            switch(node.type) with (JSON_TYPE)
            {
                case NULL:
                    return Config();
                case TRUE:
                    return Config(true);
                case FALSE:
                    return Config(false);
                case INTEGER:
                    return Config(node.integer);
                case UINTEGER:
                    return Config(node.uinteger);
                case FLOAT:
                    return Config(node.floating);
                case STRING:
                    return Config(node.str);
                case ARRAY:
                {
                    Config[] arr;
                    foreach(JSONValue ch; node.array)
                        arr ~= convert(ch);
                    return Config(arr);
                }
                case OBJECT:
                {
                    Config[string] map;
                    foreach(string key, JSONValue ch; node.object)
                        map[key] = convert(ch);

                    return Config(map);
                }
                default:
                    return Config();
            }
        }

        return convert(root);
    }
}



unittest
{
    auto loader = new JsonConfigLoader();
    auto conf = loader.loadConfigString(`{"host": "localhost", "port": 44}`);
    assert("host" in conf);
    assert("port" in conf);
    assert(conf.get!int("port") == 44);
}

